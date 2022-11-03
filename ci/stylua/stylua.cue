package stylua

import (
	"list"

	"dagger.io/dagger"

	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Lint: {
	contents:       dagger.#FS
	rust_version:   string | *"1"
	alpine_version: string | *"3.16"

	packages: ["gcc", "libc-dev", "bash"]

	_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "rust:\(rust_version)-alpine\(alpine_version)"
			},
			docker.#Run & {
				command: {
					name: "apk"
					args: list.Concat([["add"], packages])
					flags: {
						"-U":         true
						"--no-cache": true
					}
				}
			},
			docker.#Run & {
				command: {
					name: "sh"
					args: ["-c", "cargo install stylua"]
				}
			},
		]
	}

	bash.#Run & {
		input: _build.output
		mounts: src: {
			dest:       "/src"
			"contents": contents
		}
		workdir: "/src"
		script: contents: #"""
			find . -name '*.lua' -not -path '*/cue.mod/*' -print | time xargs stylua
			  modified="$(git status -s . | grep -e "^ M"  | grep "\.cue" | cut -d ' ' -f3 || true)"
			  test -z "$modified" || (echo -e "linting error in:\n${modified}" > /dev/stderr ; false)
			"""#
	}
}
