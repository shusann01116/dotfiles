package util_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/shusann01116/dotfiles/pkg/util"
)

// TestComputeDirHash tests the ComputeDirHash function
func TestComputerDirHash(t *testing.T) {
	var want uint32 = 2766018715

	// get current directory
	dir, err := os.Getwd()
	if err != nil {
		t.Errorf("error getting current directory: %v", err)
	}

	testDir := filepath.Join(dir, "data")

	// compute hash
	got, err := util.ComputeDirHash(testDir)
	if got != want || err != nil {
		t.Errorf("error computing hash: %v, %v, want %v", got, err, want)
	}
}

// TestGetExePath tests the GetExePath function
func TestGetExePath(t *testing.T) {
	// get current directory
	dir, err := os.Getwd()
	if err != nil {
		t.Errorf("error getting current directory: %v", err)
	}

	// get executable path
	got, err := util.GetExePath()
	if err != nil {
		t.Errorf("error getting executable path: %v", err)
	}

	// check that executable path is the same as the current directory
	if got != dir {
		t.Errorf("executable path (%v) != current directory (%v)", got, dir)
	}
}
