#!/bin/sh
set -e

# flags

cc=gcc
root_dir=~/aqua-root
data_dir=/usr/share/aqua
bin_dir=/usr/local/bin/aqua
cc_flags="-DKOS_DEFAULT_DEVICES_PATH=\"$data_dir/devices\" -DKOS_DEFAULT_ROOT_PATH=\"$root_dir\" -DKOS_DEFAULT_BOOT_PATH=\"$root_dir/boot.zpk\""

# parse arguments

echo "[AQUA Unix Builder] AQUA Unix Builder"
echo "[AQUA Unix Builder] Parsing arguments ..."

update=false
compile_devices=false
compile_kos=false
platform=desktop
compile_compiler=false
install=false
uninstall=false
git_prefix=https://github.com

while test $# -gt 0; do
    if   [ $1 = --update    ]; then update=true
    elif [ $1 = --devices   ]; then compile_devices=true
    elif [ $1 = --kos       ]; then compile_kos=true
    elif [ $1 = --compiler  ]; then compile_compiler=true
    elif [ $1 = --install   ]; then install=true
    elif [ $1 = --uninstall ]; then uninstall=true
    elif [ $1 = --git-ssh   ]; then git_prefix=ssh://git@github.com
    elif [ $1 = --platform  ]; then platform=$2; shift
    
    else
        echo "[AQUA Unix Builder] ERROR Unknown argument '$1' (read README.md for help)"
        exit 1
    fi

    shift
done

# setup

echo "[AQUA Unix Builder] Setting up ..."
mkdir -p src
mkdir -p bin

if [ $install = true ]; then
    if [ $uninstall = true ]; then
        echo "[AQUA Unix Builder] ERROR Both the `--uninstall` and `--install` arguments were passed"
        install=false
        exit 1
    fi

    if [ ! -f "bin/kos" ]; then compile_kos=true; fi
    if [ ! -d "bin/devices" ]; then compile_devices=true; fi
fi

if   [ $platform = desktop  ]; then cc_flags="$cc_flags -DKOS_PLATFORM=KOS_PLATFORM_DESKTOP -lSDL2 -lGL"
elif [ $platform = broadcom ]; then cc_flags="$cc_flags -DKOS_PLATFORM=KOS_PLATFORM_BROADCOM -Wno-int-to-pointer-cast -Wno-pointer-to-int-cast -L/opt/vc/lib/ -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvcos -lvchiq_arm -L/opt/vc/src/hello_pi/libs/ilclient -I/opt/vc/include/ -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I./ -I/src/libs/ilclient"

else
    echo "[AQUA Unix Builder] ERROR Unknown platform '$platform'"
    exit 1
fi

# download missing components

echo "[AQUA Unix Builder] Downloading potentially missing components ..."

( if [ ! -d src/kos ]; then
    git clone $git_prefix/inobulles/aqua-kos --depth 1 -b master
    mv aqua-kos src/kos
fi

if [ ! -d src/kos/zvm ]; then
    git clone $git_prefix/inobulles/aqua-zvm --depth 1 -b master
    mv aqua-zvm src/kos/zvm
fi ) &

( if [ ! -d src/devices ]; then
    git clone $git_prefix/inobulles/aqua-devices --depth 1 -b master
    mv aqua-devices src/devices
fi ) &

( if [ $compile_compiler = true ] && [ ! -d src/compiler ]; then
    git clone $git_prefix/inobulles/aqua-compiler --depth 1 -b master
    mv aqua-compiler src/compiler
fi ) &

wait

if [ -d src/compiler ] && [ ! `command -v iar` ]; then
    read -p "[AQUA Unix Builder] It seems as though you do not have IAR installed on your system. Press enter to install it automatically ... " a
    echo "[AQUA Unix Builder] Installing IAR ..."

    git clone https://github.com/inobulles/iar --depth 1 -b master
    ( cd iar 
    sh build.sh )
    rm -rf iar
fi

# update

if [ $update = true ]; then
    echo "[AQUA Unix Builder] Updating components ..."

    ( cd src/kos
    git pull origin master ) &

    ( cd src/kos/zvm
    git pull origin master ) &

    ( cd src/devices
    git pull origin master ) &

    ( if [ -d src/compiler ]; then
        cd src/compiler
        git pull origin master
    fi ) &

    wait
fi

# compile compiler

if [ $compile_compiler = true ]; then
    echo "[AQUA Unix Builder] Compiling compiler ..."

    rm -rf bin/compiler
    mkdir -p bin/compiler
    mkdir -p bin/compiler/langs
    cp src/compiler/compile.sh bin/compiler/compile.sh

    (cd src/compiler/langs
    for path in `find . -maxdepth 1 -type d -not -name *git* | tail -n +2 | cut -c3-`; do
        ( echo "[AQUA Unix Builder] Compiling $path language compiler ..."
        cd $path
        sh build.sh
        mv compiler ../../../../bin/compiler/langs/$path ) &
    done
    wait) &
fi

# compile devices

if [ $compile_devices = true ]; then
    echo "[AQUA Unix Builder] Compiling devices ..."

    rm -rf bin/devices
    mkdir -p bin/devices

    ( cd src/devices
    for path in `find . -maxdepth 1 -type d -not -name *git* | tail -n +2 | cut -c3-`; do
        ( echo "[AQUA Unix Builder] Compiling $path device ..."
        cd $path
        sh build.sh $cc_flags
        mv device ../../../bin/devices/$path ) &
    done
    wait ) &
fi

# compile kos

if [ $compile_kos = true ]; then
    echo "[AQUA Unix Builder] Compiling KOS ..."
    rm -f bin/kos
    $cc src/kos/glue.c -o bin/kos -std=gnu99 -no-pie -ldl $cc_flags &
fi

# install

wait # wait until everything has finished compiling

if [ $install = true ]; then
    echo "[AQUA Unix Builder] Installing binaries ..."
    sudo cp bin/kos $bin_dir

    if [ ! -d $root_dir ]; then
        echo "[AQUA Unix Builder] Downloading default root directory ..."
        git clone $git_prefix/inobulles/aqua-root --depth 1 -b master
        mv aqua-root $root_dir
    fi

    echo "[AQUA Unix Builder] Creating config files ..."
    
    sudo mkdir -p $data_dir
    sudo cp -r bin/devices $data_dir

    if [ -d bin/compiler ]; then
        echo "[AQUA Unix Builder] Installing compiler ..."
        
        sudo cp -r bin/compiler $data_dir
        sudo rm -f $bin_dir-compile
        sudo echo -e "#!/bin/sh\nset -e\nsh $data_dir/compiler/compile.sh \$*\nexit 0" | sudo tee $bin_dir-compile > /dev/null
        sudo chmod +x $bin_dir-compile
    fi
fi

# uninstall

if [ $uninstall = true ]; then
    echo "[AQUA Unix Builder] Uninstalling binaries ..."
    rm -rf bin
    
    sudo rm -rf $bin_dir
    sudo rm -rf $bin_dir-compile
    sudo rm -rf $data_dir
fi

echo "[AQUA Unix Builder] Done"
exit 0