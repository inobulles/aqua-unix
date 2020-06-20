#!/bin/sh
set -e

# flags

cc=gcc
root_dir=~/aqua-root
data_dir=/usr/share/aqua
bin_dir=/usr/local/bin/aqua
cc_flags="-DKOS_DEFAULT_DEVICES_PATH=\"$data_dir/devices\" -DKOS_DEFAULT_ROOT_PATH=\"$root_dir\" -DKOS_DEFAULT_BOOT_PATH=\"$root_dir/boot.zpk\" -DKOS_PLATFORM=KOS_PLATFORM_DESKTOP -lSDL2 -lGL"

# parse arguments

echo "[AQUA Unix builder] AQUA Unix builder"
echo "[AQUA Unix builder] Parsing arguments ..."

update=false
compile_devices=false
compile_kos=false
install=false
uninstall=false
git_prefix=https://github.com

while test $# -gt 0; do
    if   [ $1 = --update    ]; then update=true
    elif [ $1 = --devices   ]; then compile_devices=true
    elif [ $1 = --kos       ]; then compile_kos=true
    elif [ $1 = --install   ]; then install=true
    elif [ $1 = --uninstall ]; then uninstall=true
    elif [ $1 = --git-ssh   ]; then git_prefix=ssh://git@github.com

    else
        echo "[AQUA Unix builder] ERROR Unknown argument '$1' (read README.md for help)"
        exit 1
    fi

    shift
done

# setup

echo "[AQUA Unix builder] Setting up ..."
mkdir -p source
mkdir -p compiled

if [ $install = true ]; then
    if [ $uninstall = true ]; then
        echo "[AQUA Unix builder] ERROR Both the `--uninstall` and `--install` arguments were passed"
        install=false
        exit 1
    fi

    if [ ! -f "compiled/kos" ]; then compile_kos=true; fi
    if [ ! -d "compiled/devices" ]; then compile_devices=true; fi
fi

# download missing components

echo "[AQUA Unix builder] Downloading potentially missing components ..."

( if [ ! -d source/kos ]; then
    git clone $git_prefix/inobulles/aqua-kos --depth 1 -b master
    mv aqua-kos source/kos
fi

if [ ! -d source/kos/zvm ]; then
    git clone $git_prefix/inobulles/aqua-zvm --depth 1 -b master
    mv aqua-zvm source/kos/zvm
fi ) &

( if [ ! -d source/devices ]; then
    git clone $git_prefix/inobulles/aqua-devices --depth 1 -b master
    mv aqua-devices source/devices
fi ) &

wait

# update

if [ $update = true ]; then
    echo "[AQUA Unix builder] Updating components ..."

    ( cd source/kos
    git pull origin master ) &

    ( cd source/kos/zvm
    git pull origin master ) &

    ( cd source/devices
    git pull origin master ) &

    wait
fi

# compile devices

if [ $compile_devices = true ]; then
    echo "[AQUA Unix builder] Compiling devices ..."

    rm -rf compiled/devices
    mkdir -p compiled/devices

    ( cd source/devices
    for path in `find . -maxdepth 1 -type d -not -name *git* | tail -n +2`; do
        ( echo "[AQUA Unix builder] Compiling $path device ..."
        cd $path
        sh build.sh $cc_flags
        mv device ../../../compiled/devices/$path ) &
    done
    wait ) &
fi

# compile kos

if [ $compile_kos = true ]; then
    echo "[AQUA Unix builder] Compiling KOS ..."
    rm -f compiled/kos
    $cc source/kos/glue.c -o compiled/kos -std=gnu99 -no-pie -ldl $cc_flags &
fi

# install

wait # wait until everything has finished compiling

if [ $install = true ]; then
    echo "[AQUA Unix builder] Installing binaries ..."
    sudo cp compiled/kos $bin_dir

    if [ ! -d $root_dir ]; then
        echo "[AQUA Unix builder] Downloading default root directory ..."
        git clone $git_prefix/inobulles/aqua-root --depth 1 -b master
        mv aqua-root $root_dir
    fi

    echo "[AQUA Unix builder] Creating config files ..."
    
    sudo mkdir -p $data_dir
    sudo cp -r compiled/devices $data_dir
fi

# uninstall

if [ $uninstall = true ]; then
    echo "[AQUA Unix builder] Uninstalling binaries ..."
    rm -rf compiled
    
    sudo rm -rf $bin_dir
    sudo rm -rf $data_dir
fi

echo "[AQUA Unix builder] Done"
exit 0