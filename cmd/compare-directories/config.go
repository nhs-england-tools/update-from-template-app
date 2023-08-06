package main

import (
	"fmt"
	"io/ioutil"

	"gopkg.in/yaml.v3"
)

type ConfigRules struct {
	Copy   []string `yaml:"copy"`
	Delete []string `yaml:"delete"`
	Ignore []string `yaml:"ignore"`
}

type Config struct {
	File    string
	Content struct {
		Rules   ConfigRules `yaml:"rules"`
		Version struct {
			File string `yaml:"file"`
		} `yaml:"version"`
	}
}

func parseConfigFile(file string) (*Config, error) {

	config := &Config{File: file}

	// Read config file
	content, err := ioutil.ReadFile(file)
	if err != nil {
		return config, fmt.Errorf("%s", err)
	}

	// Parse config file content
	err = yaml.Unmarshal(content, &config.Content)
	if err != nil {
		return config, fmt.Errorf("%s", err)
	}

	return config, nil
}
