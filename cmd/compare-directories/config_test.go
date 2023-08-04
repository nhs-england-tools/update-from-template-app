package main

import (
	"testing"
)

func TestReadConfig(t *testing.T) {

	t.Run("it should read config", func(t *testing.T) {
		// Arrange & Act
		config, _ := readConfig(".config.yaml")
		// Assert
		if len(config.Update.Ignore) == 0 {
			t.Errorf("%s", "Unable to read the config")
		}
	})
}
