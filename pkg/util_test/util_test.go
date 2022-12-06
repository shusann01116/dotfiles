package util_test

import (
	"os"
	"testing"

	"github.com/shusann01116/dotfiles/pkg/util"
)

// TestExecuteShellCmd tests the ExecuteShellCmd function
func TestExecuteShellCmd(t *testing.T) {
	// get current directory
	want, err := os.Getwd()
	if err != nil {
		t.Errorf("error getting current directory: %v", err)
	}

	cmd := "pwd"
	got, err := util.ExecuteShellCmd(cmd, want)
	if err != nil {
		t.Errorf("error executing shell command: %v", err)
	}

	// check that project root directory is the same as the current directory
	if got != want {
		t.Errorf("got (%v) != want (%v)", got, want)
	}
}
