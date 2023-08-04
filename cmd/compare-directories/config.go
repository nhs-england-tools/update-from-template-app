package main

import (
	"fmt"
	"io/ioutil"

	"gopkg.in/yaml.v3"
)

type Config struct {
	Update struct {
		Ignore []string `yaml:"ignore"`
		Force  []string `yaml:"force"`
	} `yaml:"update"`
	Delete  []string `yaml:"delete"`
	Version struct {
		File string `yaml:"file"`
	} `yaml:"version"`
}

type ConfigManager struct {
	config Config
}

// readConfig reads a YAML configuration file from the given file path.
// It returns the parsed Config structure or an error if the file cannot be read
// or parsed.
func readConfig(filePath string) (Config, error) {

	// Read YAML file
	yamlFile, err := ioutil.ReadFile(filePath)
	if err != nil {
		return Config{}, fmt.Errorf("%s", err)
	}

	// Parse YAML to struct
	var config Config
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		return Config{}, fmt.Errorf("%s", err)
	}

	return config, nil
}
