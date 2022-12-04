// install dependencies

Deps.git("https://github.com/inobulles/umber")
Deps.git("https://github.com/inobulles/iar")

// install components

Deps.git("https://github.com/inobulles/aqua-kos", "bob")

// running

class Runner {
	static run(args) {
		return File.exec("kos", args)
	}
}
