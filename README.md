# aqua-unix

A script for automatically building and installing AQUA on Unix-based systems.
This help document only applies to the `build.sh` script.
If you need help using the `aqua` command, read `src/kos/README.md`, if you need help using the compiler, read `src/compiler/README.md`, and if you need help using the manager, read `src/manager/README.md`.

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

Compile all the devices ([`aqua-devices`](https://github.com/inobulles/aqua-devices), device branch set by `--devbranch`, which is `core` by default). (Their source code is downloaded by default if not already present.)

### --kos

Compile the KOS ([`aqua-kos`](https://github.com/inobulles/aqua-kos)). (Its source code is downloaded by default if not already present.)

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

### --git-ssh

Use SSH link as origin for cloning git repos.
Don't use this argument if you don't know what it does.
