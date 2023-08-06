package main

import (
	"flag"
	"fmt"
	"os"
)

type Arguments struct {
	SourceDirectory      string
	DestinationDirectory string
	ConfigurationFile    string
}

func parseCommandLineArguments() (*Arguments, error) {

	// Parse command-line arguments
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	dir1 := flag.String("source-dir", "", "Source directory")
	dir2 := flag.String("destination-dir", "", "Destination directory")
	file := flag.String("config-file", "", "Configuration file")
	flag.Parse()
	if *dir1 == "" || *dir2 == "" {
		return &Arguments{}, fmt.Errorf("%s", "Please, provide both directory paths")
	}
	if *file == "" {
		return &Arguments{}, fmt.Errorf("%s", "Please, provide configuration file path")
	}

	return &Arguments{
		SourceDirectory:      *dir1,
		DestinationDirectory: *dir2,
		ConfigurationFile:    *file,
	}, nil
}
