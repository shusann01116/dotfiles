package util

import (
	"io/ioutil"

	"gopkg.in/yaml.v3"
)

// ReadYaml reads a yaml file and unmarshal it to a given type
func ReadYaml(path string, v interface{}) error {
	// Read the yaml file and get bytes
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}

	// Unmarshal data as v
	err = yaml.Unmarshal(data, v)
	if err != nil {
		return err
	}

	return nil
}
