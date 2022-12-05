package util

import (
	"hash/crc32"
	"io/ioutil"
	"os"
	"path/filepath"
)

// ComputeDirHash calculates the hash of a directory and its contents recursively.
func ComputeDirHash(dirPath string) (uint32, error) {
	// Initialize the hash to 0
	var hash uint32 = 0

	// Read the contents of the dirctory
	files, err := ioutil.ReadDir(dirPath)
	if err != nil {
		return hash, err
	}

	// Iterate over the contents of the directory
	for _, file := range files {
		// Get the path of the file
		filePath := filepath.Join(dirPath, file.Name())

		// If the file is a directory, recursively compute the hash
		if file.IsDir() {
			dirHash, err := ComputeDirHash(filePath)
			if err != nil {
				return hash, err
			}

			// Update overall hash
			hash = hash ^ dirHash
		} else {
			// Otherwise, compute the hash of the file
			fileHash := crc32.ChecksumIEEE([]byte(filePath))
			if err != nil {
				return hash, err
			}
			hash = hash ^ fileHash
		}
	}

	return hash, nil
}

// GetExepath returns the executable file path
func GetExePath() (string, error) {
	exe, err := os.Executable()
	if err != nil {
		return "", err
	}
	return filepath.Dir(exe), nil
}
