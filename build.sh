#!/bin/sh
set -e

### TODO rewrite this script so that it doesn't break on error

# flags

[ -z $AQUA_ROOT_PATH ] && export AQUA_ROOT_PATH=$HOME/.aqua-root/
[ -z $AQUA_DATA_PATH ] && export AQUA_DATA_PATH=/usr/local/share/aqua/
[ -z $AQUA_BIN_PATH  ] && export AQUA_BIN_PATH=/usr/local/bin/aqua
[ -z $AQUA_INC_PATH  ] && export AQUA_INC_PATH=/usr/local/include/
[ -z $AQUA_LIB_PATH  ] && export AQUA_LIB_PATH=/usr/local/lib/
[ -z $AQUA_DEV_FLAGS ] && export AQUA_DEV_FLAGS=

# parse arguments

echo "[AQUA Unix Builder] AQUA Unix Builder"
echo "[AQUA Unix Builder] Parsing arguments ..."

update=false
devbranch=
compile_devices=false
compile_kos=false
compile_compiler=false
compile_manager=false
install=false
uninstall=false
auto_iar=false
auto_umber=false
git_prefix=https://github.com

while test $# -gt 0; do
	if   [ $1 = --update     ]; then update=true
	elif [ $1 = --devbranch  ]; then devbranch=$2 && shift
	elif [ $1 = --devices    ]; then compile_devices=true
	elif [ $1 = --kos        ]; then compile_kos=true
	elif [ $1 = --compiler   ]; then compile_compiler=true
	elif [ $1 = --manager    ]; then compile_manager=true
	elif [ $1 = --install    ]; then install=true
	elif [ $1 = --uninstall  ]; then uninstall=true
	elif [ $1 = --auto-iar   ]; then auto_iar=true
	elif [ $1 = --auto-umber ]; then auto_umber=true
	elif [ $1 = --git-ssh    ]; then git_prefix=ssh://git@github.com

	else
		echo "[AQUA Unix Builder] ERROR Unknown argument '$1' (read README.md for help)"
		exit 1
	fi

	shift
done

# download missing components

echo "[AQUA Unix Builder] Downloading potentially missing components ..."

if [ ! -d src/kos/ ]; then
	git clone $git_prefix/inobulles/aqua-kos src/kos/ --depth 1 -b main &
fi

if [ ! -d src/zvm/ ]; then
	git clone $git_prefix/inobulles/aqua-zvm src/zvm/ --depth 1 -b main &
fi

if [ ! -d src/devices/ ]; then
	if [ ! $devbranch ]; then
		devbranch=core
	fi

	git clone $git_prefix/inobulles/aqua-devices src/devices/ -b $devbranch &
fi

if [ $compile_compiler = true ]; then
	if [ ! -d src/compiler/ ]; then
		git clone $git_prefix/inobulles/aqua-compiler src/compiler/ --depth 1 -b main &
	fi

	if [ ! -d src/lib/ ]; then
		git clone $git_prefix/inobulles/aqua-lib src/lib/ --depth 1 -b main &
	fi
fi

if [ $compile_manager = true ] && [ ! -d src/manager/ ]; then
	git clone $git_prefix/inobulles/aqua-manager src/manager/ --depth 1 -b main &
fi

wait

# update

if [ $update = true ]; then
	echo "[AQUA Unix Builder] Updating components ..."

	( cd src/kos/
	git pull origin main ) &

	( cd src/zvm/
	git pull origin main ) &

	( cd src/devices/

	if [ ! $devbranch ]; then
		devbranch=$(git symbolic-ref --short HEAD)
	fi

	git fetch
	git checkout $devbranch
	git pull origin $devbranch ) &

	( if [ -d src/compiler/ ]; then
		cd src/compiler/
		git pull origin main
	fi ) &

	( if [ -d src/lib/ ]; then
		cd src/lib/
		git pull origin main
	fi ) &

	( if [ -d src/manager/ ]; then
		cd src/manager/
		git pull origin main
	fi ) &

	wait
fi

cc_flags="
	-g
	-pthread -lm -lexecinfo
	-std=c99
	-D_DEFAULT_SOURCE
	-I$AQUA_INC_PATH
	-L$AQUA_LIB_PATH
	-liar
	-lumber
	-Wno-unused-command-line-argument
	-Isrc/zvm
	-DKOS_DEFAULT_DEVICES_PATH=\"$AQUA_DATA_PATH/devices/\"
	-DKOS_DEFAULT_ROOT_PATH=\"$AQUA_ROOT_PATH\"
	-DKOS_DEFAULT_BOOT_PATH=\"$AQUA_ROOT_PATH/boot.zpk\""

# detect if we're running under WSL

if [ -f /proc/version ] && [ "$(grep "Microsoft" /proc/version)" ]; then
	cc_flags="$cc_flags -D__WSL__"
fi

# setup

echo "[AQUA Unix Builder] Setting up ..."

mkdir -p src/
mkdir -p bin/

if [ $install = true ]; then # make sure that, if we're installing, both the KOS and devices are compiled
	if [ $uninstall = true ]; then
		echo "[AQUA Unix Builder] ERROR Both the '--uninstall' and '--install' arguments were passed"
		install=false
		exit 1
	fi

	if [ ! -f bin/kos ]; then compile_kos=true; fi
	if [ ! -d bin/devices/ ]; then compile_devices=true; fi
fi

wait

# check to see if 'iar' is installed and prompt to install it if it's not

if [ ! $(command -v iar) ] || [ ! -f /usr/local/lib/libiar.a ] || [ ! -f /usr/local/lib/libiar.so ] || [ ! -f /usr/local/include/iar.h ]; then
	if [ $auto_iar = false ]; then
		read -p "[AQUA Unix Builder] It seems as though you do not have the IAR library and command line utility installed on your system. Press enter to install it automatically ... " _
	fi

	echo "[AQUA Unix Builder] Installing IAR ..."

	iar_dir=$(mktemp -dt iar-XXXXXXX)

	git clone https://github.com/inobulles/iar $iar_dir --depth 1 -b main

	( cd $iar_dir
	sh build.sh )

	rm -rf $iar_dir
fi

# check to see if libumber is installed and prompt to install it if it's not

if [ ! -f /usr/local/lib/libumber.a ] || [ ! -f /usr/local/lib/libumber.so ] || [ ! -f /usr/local/include/umber.h ]; then
	if [ $auto_umber = false ]; then
		read -p "[AQUA Unix Builder] It seems as though you do not have the Umber library installed on your system. Press enter to install it automatically ... " _
	fi

	echo "[AQUA Unix Builder] Installing Umber ..."

	umber_dir=$(mktemp -dt umber-XXXXXXX)

	git clone https://github.com/inobulles/umber $umber_dir --depth 1 -b main

	( cd $umber_dir
	sh build.sh )

	rm -rf $umber_dir
fi

# compile compiler

if [ $compile_compiler = true ]; then
	mkdir -p bin/compiler/
fi

if [ -d bin/compiler/ ]; then
	export COMPILER_BIN=$(realpath bin/compiler/)
fi

if [ $compile_compiler = true ]; then
	echo "[AQUA Unix Builder] Compiling compiler ..."

	rm -rf $COMPILER_BIN
	mkdir -p $COMPILER_BIN/langs/
	mkdir -p $COMPILER_BIN/targs/

	( cd src/compiler
		cc main.c -o $COMPILER_BIN/compiler -I. \
			-DCOMPILER_DIR_PATH=\"$AQUA_DATA_PATH/compiler/\" $cc_flags &

		( cd langs
		for path in $(find -L . -maxdepth 1 -type d -not -name ".*" | cut -c3-); do
			echo "[AQUA Unix Builder] Compiling $path language ..."

			( cd $path

			sh build.sh -I.. $cc_flags
			mv bin $COMPILER_BIN/langs/$path ) &
		done
		wait ) &

		( cd targs
		for path in $(find -L . -maxdepth 1 -type d -not -name ".*" | cut -c3-); do
			echo "[AQUA Unix Builder] Compiling $path target ..."

			( cd $path

			sh build.sh -I.. $cc_flags
			mv bin $COMPILER_BIN/targs/$path ) &
		done
		wait ) &
	wait ) &
fi

# compiler manager

if [ $compile_manager = true ]; then
	echo "[AQUA Unix Builder] Compiling manager ..."
	cc src/manager/main.c -o bin/manager -lcjson $cc_flags &
fi

# compile devices

if [ $compile_devices = true ]; then
	mkdir -p bin/devices/
fi

if [ -d bin/devices/ ]; then
	export DEVICES_BIN=$(realpath bin/devices/)
fi

if [ $compile_devices = true ]; then
	echo "[AQUA Unix Builder] Compiling devices ..."

	rm -rf $DEVICES_BIN
	mkdir -p $DEVICES_BIN

	( cd src/devices
	for path in $(find -L . -maxdepth 1 -type d -not -name ".*" | cut -c3-); do
		echo "[AQUA Unix Builder] Compiling $path device ..."

		( sh $path/build.sh -I. \
			$path/main.c -o $DEVICES_BIN/$path.device \
			$cc_flags $AQUA_DEV_FLAGS

		if [ -d assets/ ]; then
			cp -R assets/ $DEVICES_BIN/$path
		fi ) &
	done
	wait ) &
fi

# compile kos

if [ $compile_kos = true ]; then
	echo "[AQUA Unix Builder] Compiling KOS ..."
	rm -f bin/kos
	cc src/kos/main.c -o bin/kos -ldl $cc_flags &
fi

# install

wait # wait until everything has finished compiling

if [ $install = true ]; then
	echo "[AQUA Unix Builder] Installing binaries ..."
	su_list="cp $(pwd)/bin/kos $AQUA_BIN_PATH"

	if [ ! -d $AQUA_ROOT_PATH ]; then
		echo "[AQUA Unix Builder] Downloading default root directory ..."
		git clone $git_prefix/inobulles/aqua-root $AQUA_ROOT_PATH --depth 1 -b main
	fi

	echo "[AQUA Unix Builder] Creating config files ..."

	su_list="$su_list && rm -rf $AQUA_DATA_PATH"
	su_list="$su_list && mkdir -p $AQUA_DATA_PATH"

	if [ -d bin/devices/ ]; then
		su_list="$su_list && cp -r $DEVICES_BIN $AQUA_DATA_PATH"
	fi

	if [ -d bin/compiler/ ]; then
		echo "[AQUA Unix Builder] Installing compiler ..."

		su_list="$su_list && cp -r $COMPILER_BIN $AQUA_DATA_PATH"

		echo -e "#!/bin/sh\nset -e\n$AQUA_DATA_PATH/compiler/compiler \"\$@\"\nexit 0" > $COMPILER_BIN.sh
		chmod +x $COMPILER_BIN.sh

		su_list="$su_list && mv $COMPILER_BIN.sh $AQUA_BIN_PATH-compiler"
	fi

	if [ -d src/lib/ ]; then
		echo "[AQUA Unix Builder] Installing library ..."
		su_list="$su_list && cp -r $(pwd)/src/lib $AQUA_DATA_PATH"
	fi

	if [ -f bin/manager ]; then
		echo "[AQUA Unix Builder] Installing manager ..."
		su_list="$su_list && mv $(pwd)/bin/manager $AQUA_BIN_PATH-manager"
	fi

	echo $su_list
	su -l root -c "$su_list"
fi

# uninstall

if [ $uninstall = true ]; then
	echo "[AQUA Unix Builder] Uninstalling binaries ..."

	rm -rf bin
	su -l root -c "rm -rf $AQUA_BIN_PATH $AQUA_BIN_PATH-compiler $AQUA_BIN_PATH-manager $AQUA_DATA_PATH"

	echo -e "[AQUA Unix Builder] \e[41mIMPORTANT:\e[0m The AQUA root directory ($AQUA_ROOT_PATH) is not deleted by this command. You'll have to delete it manually if you want it gone, nor are the files installed by IAR or Umber (in case they were installed with this tool)."
fi

echo "[AQUA Unix Builder] Done"
exit 0
