package test

import(
    "dagger.io/dagger"
    "universe.dagger.io/docker"
    "universe.dagger.io/bash"
)

dagger.#Plan & {
    client: filesystem: {
        ".": read: contents: dagger.#FS
        "./.bin": read: contents: dagger.#FS
    }

    _image: docker.#Pull & {
        source: "ubuntu:latest"
    }

    actions: {
        test: {
            install: {
                runInstaller: bash.#Run & {
                    input: _image.output
                    script: {
                        directory: client.filesystem."./.bin".read.contents
                        filename: "install.sh"
                    }
                }
                verify: bash.#Run & {
                    input: runInstaller.output
                    script: {
                        contents: "source ~/.zshrc"
                    }
                }
            }
        }
    }
}
