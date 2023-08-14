package main

import (
	"fmt"
	"io/ioutil"

	"gopkg.in/yaml.v3"
)

type ConfigRules struct {
	Update []string `yaml:"update"`
	Delete []string `yaml:"delete"`
	Ignore []string `yaml:"ignore"`
}

type Config struct {
	Rules ConfigRules `yaml:"rules"`
}

type TemplateConfig struct {
	Rules struct {
		Ignore []string `yaml:"ignore"`
	} `yaml:"update-from-template"`
}

func parseConfigFiles(appFile, templateFile string) (*Config, error) {

	config := &Config{}
	// Read app config file
	appContent, err := ioutil.ReadFile(appFile)
	if err != nil {
		return config, fmt.Errorf("%s", err)
	}
	// Parse app config file content
	err = yaml.Unmarshal(appContent, &config)
	if err != nil {
		return config, fmt.Errorf("%s", err)
	}

	templateConfig := &TemplateConfig{}
	// Read template config file
	templateContent, err := ioutil.ReadFile(templateFile)
	if err == nil {
		// Parse template config file content
		err = yaml.Unmarshal(templateContent, &templateConfig)
		if err != nil {
			return config, fmt.Errorf("%s", err)
		}
	}

	config.Rules.Ignore = append(config.Rules.Ignore, templateConfig.Rules.Ignore...)

	return config, nil
}
