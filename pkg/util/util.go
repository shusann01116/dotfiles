package util

import (
	"fmt"
	"os/exec"
	"strings"
)

// ExecuteShellCmds executes a list of commands as shell script in passed workdir
func ExecuteShellCmds(cmds []string, workdir string) error {
	for _, cmd := range cmds {
		_, err := ExecuteShellCmd(cmd, workdir)
		if err != nil {
			return err
		}
	}
	return nil
}

// ExecuteShellCmd executes a command as a shell script in workdir
func ExecuteShellCmd(str string, workdir string) (string, error) {
	// execute cmd as shell script
	fmt.Printf("executing %q in %q\n\n", str, workdir)
	cmd := exec.Command("sh", "-c", str)

	// Run the command and capture the output
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}
	fmt.Printf("%s", output)

	return strings.TrimSpace(string(output)), nil
}
