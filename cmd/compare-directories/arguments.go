package main

import (
	"flag"
	"fmt"
	"os"
)

type Arguments struct {
	Dir1 *string
	Dir2 *string
	Cfg  *string
}

// parseArguments parses the command-line arguments and returns the parsed
// Arguments structure or an error if the arguments are invalid.
func parseArguments() (Arguments, error) {

	// Parse command-line arguments
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	dir1Ptr := flag.String("dir1", "", "First directory path")
	dir2Ptr := flag.String("dir2", "", "Second directory path")
	cfgPtr := flag.String("cfg", "", "Configuration file")
	flag.Parse()
	if *dir1Ptr == "" || *dir2Ptr == "" {
		return Arguments{}, fmt.Errorf("%s", "Please provide both directory paths")
	}

	return Arguments{
		Dir1: dir1Ptr,
		Dir2: dir2Ptr,
		Cfg:  cfgPtr,
	}, nil
}
