package main

import (
	"github.com/nhs-england-tools/update-from-template-action/cmd/compare-directories/ignore"
)

type Rules struct {
	Copy   ignore.GitIgnore
	Delete ignore.GitIgnore
	Ignore ignore.GitIgnore
}

const (
	COPY   = "copy"
	DELETE = "delete"
	IGNORE = "ignore"
)

func parseConfigRules(configRules *ConfigRules) *Rules {

	copy := ignore.CompileIgnoreLines(configRules.Copy...)
	delete := ignore.CompileIgnoreLines(configRules.Delete...)
	ignore := ignore.CompileIgnoreLines(configRules.Ignore...)
	rules := &Rules{
		Copy:   *copy,
		Delete: *delete,
		Ignore: *ignore,
	}

	return rules
}

func (rules *Rules) action(path string) string {

	if rules.shouldCopy(path) {
		return COPY
	} else if rules.shouldDelete(path) {
		return DELETE
	} else if rules.shouldIgnore(path) {
		return IGNORE
	} else {
		return COPY
	}
}

func (rules *Rules) shouldCopy(path string) bool {
	return rules.Copy.MatchesPath(path)
}

func (rules *Rules) shouldDelete(path string) bool {
	return rules.Delete.MatchesPath(path)
}

func (rules *Rules) shouldIgnore(path string) bool {
	return rules.Ignore.MatchesPath(path)
}
