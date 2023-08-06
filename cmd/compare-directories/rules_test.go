package main

import (
	"testing"
)

func TestParseConfigRules(t *testing.T) {

	t.Run("it should parse config rules", func(t *testing.T) {
		// Arrange
		cf, err := parseConfigFile("config_test.yaml")
		if err != nil {
			t.Errorf("%s", err)
		}
		// Act
		cr := parseConfigRules(&cf.Content.Rules)
		// Assert
		if cr == nil {
			t.Errorf("%s", "Check the config rules")
		}
	})
}

func TestActions(t *testing.T) {

	t.Run("it should return action accordingly", func(t *testing.T) {
		// Arrange
		cf, err := parseConfigFile("config_test.yaml")
		if err != nil {
			t.Errorf("%s", err)
		}
		// Act
		cr := parseConfigRules(&cf.Content.Rules)
		action1 := cr.action("path/to/file")
		action2 := cr.action("legacy/file")
		action3 := cr.action("custom/file")
		// Assert
		if action1 != COPY {
			t.Errorf("Check the config rules, expected '%s' action but got '%s'", COPY, action1)
		}
		if action2 != DELETE {
			t.Errorf("Check the config rules, expected '%s' action but got '%s'", DELETE, action2)
		}
		if action3 != IGNORE {
			t.Errorf("Check the config rules, expected '%s' action but got '%s'", IGNORE, action3)
		}
	})
}
