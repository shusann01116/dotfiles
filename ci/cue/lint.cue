package cue

import (
	"list"

	"dagger.io/dagger"

	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

#Lint: {
	contents:       dagger.#FS
	version:        string | *"latest"
	go_version:     string | *"1.19.2"
	alpine_version: string | *"3.16"

	packages: ["git", "bash"]

	_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "golang:\(go_version)-alpine\(alpine_version)"
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
					args: ["-c", """
                            go install cuelang.org/go/cmd/cue@\(version)
                            """]
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
			find . -name '*.cue' -not -path '*/cue.mod/*' -print | time xargs -n 1 -P 8 cue fmt -s
			modified="$(git status -s . | grep -e "^ M"  | grep "\.cue" | cut -d ' ' -f3 || true)"
			test -z "$modified" || (echo -e "linting error in:\n${modified}" > /dev/stderr ; false)
			"""#
	}
}
