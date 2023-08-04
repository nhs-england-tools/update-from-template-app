package main

import (
	"os"
	"testing"
)

func TestParseArguments(t *testing.T) {

	t.Run("it should parse dir1 and dir2", func(t *testing.T) {
		// Arrange
		os.Args = []string{"cmd", "--dir1=/path1", "--dir2=/path2"}
		// Act
		args, _ := parseArguments()
		// Assert
		if *args.Dir1 != "/path1" {
			t.Errorf("Expected dir1 to be '/path1', got '%s'", *args.Dir1)
		}
		if *args.Dir2 != "/path2" {
			t.Errorf("Expected dir2 to be '/path2', got '%s'", *args.Dir2)
		}
	})

	t.Run("it should parse cfg", func(t *testing.T) {
		// Arrange
		os.Args = []string{"cmd", "--dir1=/path1", "--dir2=/path2", "--cfg=/path/to/cfg"}
		// Act
		args, _ := parseArguments()
		// Assert
		if *args.Cfg != "/path/to/cfg" {
			t.Errorf("Expected cfg to be '/path/to/cfg', got '%s'", *args.Cfg)
		}
	})
}
