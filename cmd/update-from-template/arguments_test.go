package main

import (
	"os"
	"testing"
)

func TestParseArguments(t *testing.T) {

	t.Run("it should parse source and destination directory arguments", func(t *testing.T) {
		// Arrange
		os.Args = []string{"cmd", "--source-dir=/dir1", "--destination-dir=/dir2", "--app-config-file=/path/to/yaml", "--template-config-file=/path/to/yaml"}
		// Act
		args, _ := parseCommandLineArguments()
		// Assert
		if args.SourceDirectory != "/dir1" {
			t.Errorf("Expected source directory to be '/dir1', got '%s'", args.SourceDirectory)
		}
		if args.DestinationDirectory != "/dir2" {
			t.Errorf("Expected destination directory to be '/dir2', got '%s'", args.DestinationDirectory)
		}
	})

	t.Run("it should parse app configuration file argument", func(t *testing.T) {
		// Arrange
		os.Args = []string{"cmd", "--source-dir=/dir1", "--destination-dir=/dir2", "--app-config-file=/path/to/yaml", "--template-config-file=/path/to/yaml"}
		// Act
		args, _ := parseCommandLineArguments()
		// Assert
		if args.AppConfigurationFile != "/path/to/yaml" {
			t.Errorf("Expected cfg to be '/path/to/yaml', got '%s'", args.AppConfigurationFile)
		}
	})

	t.Run("it should parse template configuration file argument", func(t *testing.T) {
		// Arrange
		os.Args = []string{"cmd", "--source-dir=/dir1", "--destination-dir=/dir2", "--app-config-file=/path/to/yaml", "--template-config-file=/path/to/yaml"}
		// Act
		args, _ := parseCommandLineArguments()
		// Assert
		if args.TemplateConfigurationFile != "/path/to/yaml" {
			t.Errorf("Expected cfg to be '/path/to/yaml', got '%s'", args.TemplateConfigurationFile)
		}
	})
}
