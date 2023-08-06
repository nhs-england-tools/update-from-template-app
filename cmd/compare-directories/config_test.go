package main

import (
	"testing"
)

func TestParseConfigFile(t *testing.T) {

	t.Run("it should parse config file", func(t *testing.T) {
		// Arrange & Act
		cf, err := parseConfigFiles("config_test_app.yaml", "config_test_template.yaml")
		if err != nil {
			t.Errorf("%s", err)
		}
		// Assert
		if len(cf.Rules.Update) == 0 || len(cf.Rules.Delete) == 0 || len(cf.Rules.Ignore) == 0 {
			t.Errorf("%s", "Check the config file")
		}
	})
}
