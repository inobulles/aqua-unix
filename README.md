# aqua-unix
A script for automatically building and installing AQUA on Unix-based systems.
This help document only applies to the `build.sh` script. If you need help using the `aqua` command, run `aqua --help`

## Command-line arguments
Here is a list of all command-line arguments that can be passed to `build.sh` and how to use them.
They can be chained together to accomplish multiple actions at once.

### --update
Update all local repositories to their latest versions.

### --devices
Compile all the devices.

### --kos
Compile the KOS.

### --compiler
Compile the compiler.

### --install
Install the compiled binaries on the system, download the default AQUA root directory, and create config files if not already created.
Will automatically compile the KOS and devices if they are not already.

### --uninstall
Uninstall everything installed by `--install` and clean up all files.
This will not remove the AQUA root directory, you'll have to do that manually.

### --git-ssh
Use SSH link as origin for cloning git repos.
Note that this argument is completely useless for most people, so no point using it if you don't understand what it does.
