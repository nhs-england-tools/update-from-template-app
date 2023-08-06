package main

import (
	"flag"
	"fmt"
	"os"
)

type Arguments struct {
	SourceDirectory           string
	DestinationDirectory      string
	AppConfigurationFile      string
	TemplateConfigurationFile string
}

func parseCommandLineArguments() (*Arguments, error) {

	// Parse command-line arguments
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	dir1 := flag.String("source-dir", "", "Source directory")
	dir2 := flag.String("destination-dir", "", "Destination directory")
	file1 := flag.String("app-config-file", "", "Configuration file of the Update from Template app")
	file2 := flag.String("template-config-file", "", "Configuration file for the Repository Template update")
	flag.Parse()
	if *dir1 == "" || *dir2 == "" {
		return &Arguments{}, fmt.Errorf("%s", "Please, provide both source and destination directory paths")
	}
	if *file1 == "" {
		return &Arguments{}, fmt.Errorf("%s", "Please, provide app configuration file path")
	}
	if *file2 == "" {
		return &Arguments{}, fmt.Errorf("%s", "Please, provide template configuration file path")
	}

	return &Arguments{
		SourceDirectory:           *dir1,
		DestinationDirectory:      *dir2,
		AppConfigurationFile:      *file1,
		TemplateConfigurationFile: *file2,
	}, nil
}
