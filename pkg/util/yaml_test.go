package util

import (
	"os"
	"path/filepath"
	"testing"
)

// TestReadYaml test ReadYaml function
func TestReadYaml(t *testing.T) {
	// get current directory
	dir, err := os.Getwd()
	if err != nil {
		t.Errorf("error getting current directory: %v", err)
	}

	testDir := filepath.Join(dir, "data")

	// get test file path
	testFile := filepath.Join(testDir, "test.yaml")

	// create test struct
	type Test struct {
		Test1 string `yaml:"test1"`
		Test2 string `yaml:"test2"`
		Test3 string `yaml:"test3"`
		Test4 struct {
			Test5 []string `yaml:"test5"`
		} `yaml:"test4"`
	}

	// create test struct
	var test Test

	// read yaml file
	err = ReadYaml(testFile, &test)
	if err != nil {
		t.Errorf("error reading yaml file: %v", err)
	}

	// check that test struct is correct
	if test.Test1 != "test1" || test.Test2 != "test2" || test.Test3 != "test3" {
		t.Errorf("error reading yaml file: %v", err)
	}

	// check that test struct is correct
	if test.Test4.Test5[0] != "test5" || test.Test4.Test5[1] != "test6" {
		t.Errorf("error reading yaml file: %v", err)
	}
}
