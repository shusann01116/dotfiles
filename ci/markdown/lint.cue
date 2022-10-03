package markdown

import (
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Lint: {
	version:  string | *"3.1.2-slim"
	rules:    [...string] | *["~MD002", "~MD013", "~MD026", "~MD036"]
	contents: dagger.#FS

	_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "ruby:\(version)"
			},
			bash.#Run & {
				script: contents: "gem install mdl"
			},
		]
	}

	docker.#Run & {
		input: _build.output
		mounts: src: core.#Mount & {
			dest:       "/src"
			"contents": contents
		}

		workdir: "/scr"
		command: {
			name: "mdl"
			args: ["-r", "\(strings.Join(rules, ","))"]
		}
	}
}
