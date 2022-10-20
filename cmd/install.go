package cmd

import (
	"github.com/pschlump/filelib"
)

func ListDirectory(path string) []string {
	if !filelib.Exists(path) {
		println("Not found")
		result := [1]string{""}
		return result[:]
	}
	return 
}
