package util

import (
	"os"
	"path/filepath"
	"testing"
)

// TestComputeDirHash tests the ComputeDirHash function
func TestComputerDirHash(t *testing.T) {
	var want uint32 = 1303633779

	// get current directory
	dir, err := os.Getwd()
	if err != nil {
		t.Errorf("error getting current directory: %v", err)
	}

	testDir := filepath.Join(dir, "data")

	// compute hash
	got, err := ComputeDirHash(testDir)
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
	got, err := GetExePath()
	if err != nil {
		t.Errorf("error getting executable path: %v", err)
	}

	// check that executable path is the same as the current directory
	if got != dir {
		t.Errorf("executable path (%v) != current directory (%v)", got, dir)
	}
}
