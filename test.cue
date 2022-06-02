package test

import(
    "dagger.io/dagger"
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
                        args: [ "install", "zsh", "openssh-client", "git", "curl", "-y" ]
                    }
                },
                docker.#Copy & {
                    contents: client.filesystem.".".read.contents
                    dest: "/src"
                }
            ]
        }
        test: {
            installer: docker.#Run & {
                input: build.output
                workdir: "/src/test"
                command: {
                    name: "./installer.sh"
                }
            }
        }
    }
}
