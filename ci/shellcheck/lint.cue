package shellcheck

import (
	"dagger.io/dagger/core"
	"dagger.io/dagger"

	"universe.dagger.io/docker"
)

#Lint: {
	version:  string | *"stable"
	contents: dagger.#FS

	_image: docker.#Pull & {
		source: "koalaman/shellcheck-alpine:\(version)"
	}

	docker.#Run & {
		input: _image.output
		mounts: src: core.#Mount & {
			dest:       "/src"
			"contents": contents
		}

		workdir: "/src"
		command: {
			name: "sh"
			args: ["-c", #"""
				shellcheck $(find . -type f -name "*.sh" | xargs echo)
				"""#]
		}
	}
}
