# aqua-unix

A script for automatically building and installing AQUA on Unix-like systems.
This help document only applies to the `build.sh` script.
If you need help using the `aqua` command, read `src/kos/README.md`, if you need help using the compiler, read `src/compiler/README.md`, and if you need help using the manager, read `src/manager/README.md`.

## Prequisites

While not all of these packages are strictly necessary for all devices on all device branches, here they all are per OS if you want to install them for peace of mind.

### aquaBSD/FreeBSD

```console
pkg install pkgconf libcjson xcb-util-image xcb-util xcb-util-wm librsvg2-rust icu pango
```

### Ubuntu

```console
sudo apt install libpng-dev librsvg2-dev libpango1.0-dev libxcb-randr0-dev
```

## Command-line arguments

Here is a list of all command-line arguments that can be passed to `build.sh` and how to use them.
They can be chained together to perform multiple actions at once.

### --update

Update all local repositories to their latest versions.

### --devbranch

Select the branch (the argument directly following this one) in the [`aqua-devices`](https://github.com/inobulles/aqua-devices) repository to use for the devices.
This won't do anything if either the `src/devices/` directory already exists, either the `--update` argument is not also passed.
By default, `--devbranch` is set to `core`.

### --devices

Compile all the devices ([`aqua-devices`](https://github.com/inobulles/aqua-devices), device branch set by `--devbranch`, which is `core` by default).
(Their source code is downloaded by default if not already present.)

### --kos

Compile the KOS ([`aqua-kos`](https://github.com/inobulles/aqua-kos)).
(Its source code is downloaded by default if not already present.)

### --compiler

Download the source code of the compiler ([`aqua-compiler`](https://github.com/inobulles/aqua-compiler)) if not already present and compile it.
This will also download the AQUA library ([`aqua-lib`](https://github.com/inobulles/aqua-lib)) if not already present either.

### --manager

Download the source code of the project manager utility ([`aqua-manager`](https://github.com/inobulles/aqua-manager)) if not already present and compile it.

### --install

Install the compiled binaries (and AQUA library if available) on the system, download the default AQUA root directory, and create config files if not already created.
Will automatically compile the KOS and devices if they are not already.
Note that this will prompt for superuser privileges, as some files will need to be installed in system directories.

### --uninstall

Uninstall everything installed by `--install` and clean up all files.
This will not remove the AQUA root directory, you'll have to do that manually.
Note that this will prompt for superuser privileges, as some binaries will need to be removed from system directories.

### --auto-iar

Don't prompt the user when installing the [IAR](https://github.com/inobulles/iar) library and command-line utility.
Useful for automated build scripts.

### --auto-umber

Don't prompt the user when installing the [Umber](https://github.com/inobulles/umber) library.
Useful for automated build scripts.

### --git-ssh

Use SSH link as origin for cloning git repos.
Don't use this argument if you don't know what it does.

## Environment variables

A variety of environment variables can be used to customize the AQUA installation to your choosing.
Here is a list of them and how to use them.
You can unset any of these environment variables to return them back to their default values by setting them equal to nothing:

```sh
% export ENVIRONMENT_VARIABLE=
```

### AQUA_ROOT_PATH

The path where the AQUA root environment is installed.
`AQUA_ROOT_PATH` is set to `$HOME/.aqua-root/` by default, where `$HOME` is the path to the current user's home directory.

### AQUA_DATA_PATH

The path where support files for AQUA components are installed (e.g., but not limited to, compiler targets, devices, &c).
`AQUA_DATA_PATH` is set to `/usr/local/share/aqua/` by default.

### AQUA_BIN_PATH

The path and prefix for AQUA binaries.
`AQUA_BIN_PATH` is set to `/usr/local/bin/aqua` by default.

### AQUA_INC_PATH

The path where AQUA library headers are installed.
`AQUA_INC_PATH` is set to `/usr/local/include/` by default.

### AQUA_LIB_PATH

The path where AQUA libraries are installed.
`AQUA_LIB_PATH` is set to `/usr/local/lib/` by default.

### AQUA_DEV_FLAGS

Flags to be passed to the compiler during the compilation of devices.
Usually this is used to set compile-time flags for devices, e.g. the `AQUABSD_ALPS_UI_WITHOUT_OGL` flag for disabling the OpenGL backend when compiling the `aquabsd.alps.ui` device.
`AQUA_DEV_FLAGS` is set to nothing by default.
