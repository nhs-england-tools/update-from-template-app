package main

import (
	"github.com/nhs-england-tools/update-from-template-action/cmd/update-from-template/ignore"
)

type Rules struct {
	Update ignore.GitIgnore
	Delete ignore.GitIgnore
	Ignore ignore.GitIgnore
}

const (
	UPDATE = "update"
	DELETE = "delete"
	IGNORE = "ignore"
)

func parseConfigRules(configRules *ConfigRules) *Rules {

	update := ignore.CompileIgnoreLines(configRules.Update...)
	delete := ignore.CompileIgnoreLines(configRules.Delete...)
	ignore := ignore.CompileIgnoreLines(configRules.Ignore...)
	rules := &Rules{
		Update: *update,
		Delete: *delete,
		Ignore: *ignore,
	}

	return rules
}

func (rules *Rules) action(path string) string {

	if rules.shouldUpdate(path) {
		return UPDATE
	} else if rules.shouldDelete(path) {
		return DELETE
	} else if rules.shouldIgnore(path) {
		return IGNORE
	} else {
		return UPDATE
	}
}

func (rules *Rules) shouldUpdate(path string) bool {
	return rules.Update.MatchesPath(path)
}

func (rules *Rules) shouldDelete(path string) bool {
	return rules.Delete.MatchesPath(path)
}

func (rules *Rules) shouldIgnore(path string) bool {
	return rules.Ignore.MatchesPath(path)
}
