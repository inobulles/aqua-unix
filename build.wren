// install dependencies

Deps.git("https://github.com/inobulles/umber")
Deps.git("https://github.com/inobulles/iar")

Deps.git("https://github.com/inobulles/aqua-kos", "bob")
Deps.git("https://github.com/inobulles/aqua-devices", "bob")

// running

class Runner {
	static run(args) {
		return File.exec("kos", args)
	}
}

// installation map
// since we don't really generate anything here, the installation map is empty
// TODO how should installation of dependencies work actually? a priori we'll want to recursively install dependencies automatically if we install a project, in which case it shouldn't be in the installation map... but does this mean 'aqua-unix' should have no installation map? idk, a lot of questions to answer 😛

var install = {}

// TODO testing

class Tests {
}

var tests = []
