package cue

import(
    "dagger.io/dagger"

    "universe.dagger.io/docker"
    "universe.dagger.io/go"
)

#Lint: {
    contents: dagger.#FS
    version: string | *"latest"

    _build: docker.#Build & {
        steps: [
            docker.#Run & {
                input: go.#Image
                comamnd: {
                    name: "go"
                    args: ["install", "cuelang.org/go/cmd/cue@\(version)"]
                }
            }
        ]
    }

    docker.#Run & {
        input: _build.output
        mounts: "src": {
            dest: "/src"
            "contents": contents
        }

        command: {
            name: "cue"
            args: ["fmt"]
        }
    }
}
