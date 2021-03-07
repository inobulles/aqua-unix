#!/bin/sh
set -e

### TODO rewrite this script so that it doesn't break on error

# flags

root_path=~/.aqua-root/
data_path=/usr/share/aqua/
bin_path=/usr/local/bin/aqua
inc_path=/usr/local/include/
lib_path=/usr/local/lib/

# note that we need to link libiar statically (because of an apparent bug with the readdir function with clang on FreeBSD)

cc_flags="
	-g
	-std=c99
	-I$inc_path
	-L$lib_path
	$lib_path/libiar.a
	-Wno-unused-command-line-argument
	-I`realpath src/kos/zvm/`
	-DKOS_DEFAULT_DEVICES_PATH=\"$data_path/devices/\"
	-DKOS_DEFAULT_ROOT_PATH=\"$root_path\"
	-DKOS_DEFAULT_BOOT_PATH=\"$root_path/boot.zpk\""

if [ -d src/compiler/ ]; then
	cc_flags="$cc_flags -I`realpath src/compiler/`"
fi

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
mkdir -p src/
mkdir -p bin/

if [ $install = true ]; then
	if [ $uninstall = true ]; then
		echo "[AQUA Unix Builder] ERROR Both the '--uninstall' and '--install' arguments were passed"
		install=false
		exit 1
	fi

	if [ ! -f bin/kos ]; then compile_kos=true; fi
	if [ ! -d bin/devices/ ]; then compile_devices=true; fi
fi

if   [ $platform = desktop  ]; then
	cc_flags="$cc_flags
		-DKOS_PLATFORM=KOS_PLATFORM_DESKTOP
		-lSDL2
		-lGL"

elif [ $platform = broadcom ]; then
	cc_flags="$cc_flags
		-DKOS_PLATFORM=KOS_PLATFORM_BROADCOM
		-L/opt/vc/lib/ -lbrcmGLESv2 -lbrcmEGL -lopenmaxil -lbcm_host -lvcos -lvchiq_arm -L/opt/vc/src/hello_pi/libs/ilclient -I/opt/vc/include/ -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux -I./ -I/src/libs/ilclient"

else
	echo "[AQUA Unix Builder] ERROR Unknown platform '$platform'"
	exit 1
fi

# download missing components

echo "[AQUA Unix Builder] Downloading potentially missing components ..."

( if [ ! -d src/kos ]; then
	git clone $git_prefix/inobulles/aqua-kos --depth 1 -b master
	mv aqua-kos/ src/kos/
fi

if [ ! -d src/kos/zvm ]; then
	git clone $git_prefix/inobulles/aqua-zvm --depth 1 -b master
	mv aqua-zvm/ src/kos/zvm/
fi ) &

( if [ ! -d src/devices ]; then
	git clone $git_prefix/inobulles/aqua-devices --depth 1 -b master
	mv aqua-devices/ src/devices/
fi ) &

( if [ $compile_compiler = true ] && [ ! -d src/compiler/ ]; then
	git clone $git_prefix/inobulles/aqua-compiler --depth 1 -b master
	mv aqua-compiler/ src/compiler/
fi ) &

wait

if [ -d src/compiler/ ]; then if [ ! `command -v iar` ] || [ ! -f /usr/local/lib/libiar.a ] || [ ! -f /usr/local/include/iar.h ]; then
	read -p "[AQUA Unix Builder] It seems as though you do not have IAR library and command line utility installed on your system. Press enter to install it automatically ... " a
	echo "[AQUA Unix Builder] Installing IAR ..."

	git clone https://github.com/inobulles/iar --depth 1 -b master
	( cd iar/
	sh build.sh )
	rm -rf iar/
fi; fi

# update

if [ $update = true ]; then
	echo "[AQUA Unix Builder] Updating components ..."

	( cd src/kos/
	git pull origin master ) &

	( cd src/kos/zvm/
	git pull origin master ) &

	( cd src/devices/
	git pull origin master ) &

	( if [ -d src/compiler ]; then
		cd src/compiler/
		git pull origin master
	fi ) &

	wait
fi

# compile compiler

if [ $compile_compiler = true ]; then
	echo "[AQUA Unix Builder] Compiling compiler ..."

	rm -rf bin/compiler/
	mkdir -p bin/compiler/langs/
	mkdir -p bin/compiler/targs/

	cc src/compiler/compile.c -o bin/compiler/compile \
		-DCOMPILER_DIR_PATH=\"$data_path/compiler/\" $cc_flags &

	( cd src/compiler/langs/
	for path in `find . -maxdepth 1 -type d -not -name ".*" | cut -c3-`; do
		( echo "[AQUA Unix Builder] Compiling $path language ..."
		cd $path
		sh build.sh $cc_flags
		mv bin ../../../../bin/compiler/langs/$path ) & # there has to be a better way than doing ../../../../ lmao
	done
	wait ) &

	( cd src/compiler/targs/
	for path in `find . -maxdepth 1 -type d -not -name ".*" | cut -c3-`; do
		( echo "[AQUA Unix Builder] Compiling $path target ..."
		cd $path
		sh build.sh $cc_flags
		mv bin ../../../../bin/compiler/targs/$path ) &
	done
	wait ) &
fi

# compile devices

if [ $compile_devices = true ]; then
	echo "[AQUA Unix Builder] Compiling devices ..."

	rm -rf bin/devices/
	mkdir -p bin/devices/

	( cd src/devices
	for path in `find . -maxdepth 1 -type d -not -name ".*" | cut -c3-`; do
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
	cc src/kos/glue.c -o bin/kos -ldl $cc_flags &
fi

# install

wait # wait until everything has finished compiling

if [ $install = true ]; then
	echo "[AQUA Unix Builder] Installing binaries ..."
	su_list="cp `pwd`/bin/kos $bin_path"

	if [ ! -d $root_path ]; then
		echo "[AQUA Unix Builder] Downloading default root directory ..."
		git clone $git_prefix/inobulles/aqua-root $root_path --depth 1 -b master
	fi

	echo "[AQUA Unix Builder] Creating config files ..."
	
	su_list="$su_list && rm -rf $data_path"
	
	su_list="$su_list && mkdir -p $data_path"
	su_list="$su_list && cp -r `pwd`/bin/devices $data_path"

	if [ -d bin/compiler/ ]; then
		echo "[AQUA Unix Builder] Installing compiler ..."

		su_list="$su_list && cp -r `pwd`/bin/compiler $data_path"

		echo -e "#!/bin/sh\nset -e\n$data_path/compiler/compile \"\$@\"\nexit 0" > bin/compile
		chmod +x bin/compile

		su_list="$su_list && mv `pwd`/bin/compile $bin_path-compile"
	fi

	su -l root -c "$su_list"
fi

# uninstall

if [ $uninstall = true ]; then
	echo "[AQUA Unix Builder] Uninstalling binaries ..."
	
	rm -rf bin
	su -l root -c "rm -rf $bin_path $bin_path-compile $data_path"

	echo -e "[AQUA Unix Builder] \e[41mIMPORTANT:\e[0m The AQUA root directory ($root_path) is not deleted by this command. You'll have to delete it manually if you want it gone."
fi

echo "[AQUA Unix Builder] Done"
exit 0
