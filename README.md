# aqua-unix

A script for automatically building and installing AQUA on Unix-based systems.
This help document only applies to the `build.sh` script.
If you need help using the `aqua` command, read `src/kos/README.md`, if you need help using the compiler, read `src/compiler/README.md`, and if you need help using the manager, read `src/manager/README.md`.

## Command-line arguments

Here is a list of all command-line arguments that can be passed to `build.sh` and how to use them.
They can be chained together to perform multiple actions at once.

### --update

Update all local repositories to their latest versions.

### --devices

Compile all the devices.

### --kos

Compile the KOS.

### --compiler

Compile the compiler.

### --manager

Compile the manager.

### --install

Install the compiled binaries on the system, download the default AQUA root directory, and create config files if not already created.
Will automatically compile the KOS and devices if they are not already.
Note that this will prompt for superuser privileges, as some binaries will need to be installed in system directories.

### --uninstall

Uninstall everything installed by `--install` and clean up all files.
This will not remove the AQUA root directory, you'll have to do that manually.
Note that this will prompt for superuser privileges, as some binaries will need to be removed from system directories.

### --git-ssh

Use SSH link as origin for cloning git repos.
Don't use this argument if you don't know what it does.