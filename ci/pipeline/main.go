package main

import (
	"context"
	"fmt"
	"os"
	"path"

	"dagger.io/dagger"
)

func main() {
	if err := test(context.Background()); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func test(ctx context.Context) error {
	fmt.Println("Testing with Dagger")

	// init dagger client
	client, err := dagger.Connect(ctx, dagger.WithLogOutput(os.Stderr))
	if err != nil {
		return err
	}
	defer client.Close()

	// create a cache volume
	brewCache := client.CacheVolume("brew-cache")
	brewTapCache := client.CacheVolume("brew-tap-cache")
	aptCache := client.CacheVolume("apt-cache")

	// resolve the relative path to the ../.. directory
	// this is where the cloned repository will be mounted
	dir, err := os.Getwd()
	if err != nil {
		return err
	}
	dir = path.Join(dir, "..", "..")

	// get reference to the local project
	src := client.Host().Directory(dir)

	// get `ubuntu` image and mount cloned repository into `ubuntu` image
	ubuntu := client.Container().From("ubuntu:latest").
		WithExec([]string{"bash", "-c", "apt-get update && apt-get install -y sudo"}).
		WithExec([]string{"bash", "-c", "useradd -m test && echo 'test ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"}).
		WithDirectory("/src", src).WithWorkdir("/src")

	// run the install script
	code, err := ubuntu.
		WithUser("test").
		WithMountedCache("/home/test/.cache/Homebrew", brewCache).
		WithMountedCache("/home/linuxbrew/.linuxbrew/Homebrew/Library/Taps", brewTapCache).
		WithMountedCache("/var/cache/apt", aptCache).
		WithExec([]string{"bash", "-c", "DEBUG=1 NONINTERACTIVE=1 /bin/bash ./install.sh"}).
		ExitCode(ctx)
	if err != nil || code != 0 {
		return fmt.Errorf("install.sh failed with code %d: %w", code, err)
	}

	return nil
}
