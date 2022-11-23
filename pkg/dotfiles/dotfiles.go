package dotfiles

import (
	"errors"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
)

type (
	Pkg struct {
		Name string
	}
	Pkgs []Pkg
)

var (
	packages Pkgs
	workdir  string
)

// Install execute a command given in list to install packages
// Packages are specified by Pkg type
func Install(pkg Pkg) error {
	// init workdir as current dir if wd doesn't exist
	if workdir == "" {
		wd, err := getwd()
		if err != nil {
			return err
		}
		workdir = wd
	}

	if fs.ValidPath(workdir) {
		return errors.New(
			fmt.Sprintf(
				"invalid path: %q\nplease try running on the directory contain package directory",
				workdir,
			),
		)
	}

	if packages.Contains(pkg) {
		log.Println(pkg, "not found")
		return errors.New("Package not found.")
	}

	return nil
}

func getwd() (string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	return filepath.Join(wd, "package"), nil
}

// getExepath returns the executable file path
func getExePath() (string, error) {
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	return filepath.Dir(exe), nil
}

// Contains returns true when Pkg array Contains target
func (pkgs Pkgs) Contains(target Pkg) bool {
	for _, p := range pkgs {
		if p.Name == target.Name {
			return true
		}
	}
	return false
}
