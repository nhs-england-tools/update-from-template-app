package main

import (
	"testing"
)

func TestParseConfigFile(t *testing.T) {

	t.Run("it should parse config file", func(t *testing.T) {
		// Arrange & Act
		cf, err := parseConfigFile("config_test.yaml")
		if err != nil {
			t.Errorf("%s", err)
		}
		// Assert
		if len(cf.Content.Rules.Copy) == 0 || len(cf.Content.Rules.Delete) == 0 || len(cf.Content.Rules.Ignore) == 0 {
			t.Errorf("%s", "Check the config file")
		}
	})
}
