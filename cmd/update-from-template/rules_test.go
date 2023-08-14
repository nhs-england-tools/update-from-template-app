package main

import (
	"testing"
)

func TestParseConfigRules(t *testing.T) {

	t.Run("it should parse config rules", func(t *testing.T) {
		// Arrange
		cf, err := parseConfigFiles("config_test_app.yaml", "config_test_template.yaml")
		if err != nil {
			t.Errorf("%s", err)
		}
		// Act
		cr := parseConfigRules(&cf.Rules)
		// Assert
		if cr == nil {
			t.Errorf("%s", "Check the config rules")
		}
	})
}

func TestActions(t *testing.T) {

	t.Run("it should return action accordingly", func(t *testing.T) {
		// Arrange
		cf, err := parseConfigFiles("config_test_app.yaml", "config_test_template.yaml")
		if err != nil {
			t.Errorf("%s", err)
		}
		// Act
		cr := parseConfigRules(&cf.Rules)
		action1 := cr.action("path/to/file")
		action2 := cr.action("legacy/file")
		action3 := cr.action("custom/file")
		action4 := cr.action("ignore/this/dir")
		// Assert
		if action1 != UPDATE {
			t.Errorf("Check the config rules, expected '%s' action but got '%s'", UPDATE, action1)
		}
		if action2 != DELETE {
			t.Errorf("Check the config rules, expected '%s' action but got '%s'", DELETE, action2)
		}
		if action3 != IGNORE {
			t.Errorf("Check the config rules, expected '%s' action but got '%s'", IGNORE, action3)
		}
		if action4 != IGNORE {
			t.Errorf("Check the config rules, expected '%s' action but got '%s'", IGNORE, action4)
		}
	})
}
