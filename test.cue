package test

import(
    "dagger.io/dagger"
    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

dagger.#Plan & {
    client: filesystem: {
        ".": read: contents: dagger.#FS
    }

    actions: {
        build: docker.#Build & {
            steps: [
                docker.#Pull & {
                    source: "ubuntu:latest"
                },
                docker.#Run & {
                    command: {
                        name: "apt"
                        args: [ "update" ]
                    }
                },
                docker.#Run & {
                    command: {
                        name: "apt"
                        args: [ "-y", "install", "zsh", "openssh-client", "git", "curl", "tmux" ]
                    }
                },
                docker.#Copy & {
                    contents: client.filesystem.".".read.contents
                    dest: "/src"
                }
            ]
        }
        install: docker.#Run & {
            input: build.output
            workdir: "/src/.bin"
            command: {
                name: "/src/.bin/install.sh"
            }
        }
        test: bash.#Run & {
            input: install.output
            script: contents: "/src/test/test.sh"
        }
    }
}
