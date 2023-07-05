package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/xeipuuv/gojsonschema"
)

type Arguments struct {
	schema *string
	output *string
}

func main() {

	args := parseArguments()

	schemaLoader := gojsonschema.NewReferenceLoader("file://" + *args.schema)
	documentLoader := gojsonschema.NewReferenceLoader("file://" + *args.output)

	result, err := gojsonschema.Validate(schemaLoader, documentLoader)
	if err != nil {
		panic(err.Error())
	}

	if result.Valid() {
		fmt.Printf("The document is valid\n")
	} else {
		fmt.Printf("The document is not valid. See errors :\n")
		for _, desc := range result.Errors() {
			fmt.Printf("- %s\n", desc)
		}
	}
}

func parseArguments() Arguments {

	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	schema := flag.String("schema", "", "Schema path")
	output := flag.String("output", "", "Output path")
	flag.Parse()

	if *schema == "" || *output == "" {
		fmt.Println("Please provide both directory paths")
		os.Exit(1)
	}

	return Arguments{
		schema: schema,
		output: output,
	}
}
