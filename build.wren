// install dependencies

Deps.git_inherit("https://github.com/inobulles/umber")
Deps.git_inherit("https://github.com/inobulles/iar")

Deps.git_inherit("https://github.com/inobulles/aqua-kos")
Deps.git_inherit("https://github.com/inobulles/aqua-devices")

// running

class Runner {
	static run(args) {
		return File.exec("kos", args)
	}
}

// installation map
// since we don't really generate anything here, the installation map is empty

var install = {}

// TODO testing

class Tests {
}

var tests = []
