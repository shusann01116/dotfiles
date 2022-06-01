package test

import(
    "dagger.io/dagger"
    "universe.dagger.io/docker"
    "universe.dagger.io/bash"
)

ubuntu: {
    _build: docker.#Build & {
        steps: [
            docker.#Pull & {
                source: "ubuntu:latest"
            }
        ]
    }
    image: _build.output
}

dagger.#Plan & {
    client: filesystem: {
        ".": read: contents: dagger.#FS
    }

    actions: {
        test: {
            installer: bash.#Run & {
                input: ubuntu.image
                script: {
                    directory: client.filesystem.".".read.contents
                    filename: "test/installer.sh"
                }
            }
        }
    }
}
