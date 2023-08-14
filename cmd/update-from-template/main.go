package main

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode"

	"github.com/agnivade/levenshtein"
)

type FileInfo struct {
	Path          string    `json:"path"`
	Date          time.Time `json:"date"`
	IsDirectory   bool      `json:"isDirectory"`
	Size          int64     `json:"size"`
	Hash          string    `json:"hash"`
	IsText        bool      `json:"isText"`
	NumberOfLines int       `json:"numberOfLines"`
}

type Exists struct {
	Source      bool `json:"source"`
	Destination bool `json:"destination"`
}

type TextFileComparisonInfo struct {
	Exists Exists `json:"exists"`
	Match  int    `json:"match"`
	Action string `json:"action"`
}

type Result struct {
	Source      map[string]FileInfo               `json:"source"`
	Destination map[string]FileInfo               `json:"destination"`
	Comparison  map[string]TextFileComparisonInfo `json:"comparison"`
}

func main() {

	// Parse the command-line arguments
	args, err := parseCommandLineArguments()
	if err != nil {
		log.Fatalf("Error while parsing command-line arguments: %s\n", err)
	}

	// Parse the config file
	config, err := parseConfigFiles(args.AppConfigurationFile, args.TemplateConfigurationFile)
	if err != nil {
		log.Fatalf("Error while parsing config files: %s\n", err)
	}

	// Walk the directories
	source, destination, err := walk(&args.SourceDirectory, &args.DestinationDirectory)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	result := compare(source, destination, &config.Rules)
	printAsJson(result)
}

func walk(dir1, dir2 *string) (map[string]FileInfo, map[string]FileInfo, error) {

	source := make(map[string]FileInfo)
	destination := make(map[string]FileInfo)

	// Walk the source directory
	err := filepath.Walk(*dir1, func(path string, info os.FileInfo, err error) error {
		if info.IsDir() && info.Name() == ".git" {
			return filepath.SkipDir
		}
		if !info.IsDir() {
			file, _ := filepath.Rel(*dir1, path)
			if file == "." || file == ".git" {
				return nil
			}
			absPath, _ := filepath.Abs(path)
			source[file] = FileInfo{
				Path:        absPath,
				Date:        info.ModTime(),
				IsDirectory: false,
				Size:        info.Size(),
			}
		}
		return nil
	})
	if err != nil {
		return nil, nil, err
	}

	// Walk the destination directory
	err = filepath.Walk(*dir2, func(path string, info os.FileInfo, err error) error {
		if info.IsDir() && info.Name() == ".git" {
			return filepath.SkipDir
		}
		if !info.IsDir() {
			file, _ := filepath.Rel(*dir2, path)
			if file == "." || file == ".git" {
				return nil
			}
			absPath, _ := filepath.Abs(path)
			destination[file] = FileInfo{
				Path:        absPath,
				Date:        info.ModTime(),
				IsDirectory: false,
				Size:        info.Size(),
			}
		}
		return nil
	})
	if err != nil {
		return nil, nil, err
	}

	return source, destination, nil
}

func compare(source, destination map[string]FileInfo, configRules *ConfigRules) Result {

	comparison := make(map[string]TextFileComparisonInfo)
	rules := parseConfigRules(configRules)

	for file, info1 := range source {
		source[file], _ = populateInfo(info1)
		if info2, exists := destination[file]; exists {
			destination[file], _ = populateInfo(info2)

			levenshteinDistance, err := computeMatch(info1.Path, info2.Path)
			if err != nil {
				fmt.Printf("Failed to compare file %s: %s\n", file, err)
				continue
			}
			match := 100 - int(float64(levenshteinDistance)/float64(info1.Size+info2.Size)*100)
			comparison[file] = TextFileComparisonInfo{
				Exists: Exists{
					Source:      true,
					Destination: true,
				},
				Match:  match,
				Action: rules.action(file),
			}
		} else {
			comparison[file] = TextFileComparisonInfo{
				Exists: Exists{
					Source:      true,
					Destination: false,
				},
				Match:  0,
				Action: rules.action(file),
			}
		}
	}
	for file, info := range destination {
		if _, exists := source[file]; !exists {
			destination[file], _ = populateInfo(info)
		}
	}

	// Add files to delete
	for _, file := range configRules.Delete {
		if _, exists := destination[file]; exists {
			if _, exists := comparison[file]; !exists {
				comparison[file] = TextFileComparisonInfo{
					Exists: Exists{
						Source:      false,
						Destination: true,
					},
					Action: DELETE,
				}
			} else {
				comparison[file] = TextFileComparisonInfo{
					Exists: comparison[file].Exists,
					Match:  comparison[file].Match,
					Action: DELETE,
				}
			}
		}
	}

	return Result{source, destination, comparison}
}

func populateInfo(fileInfo FileInfo) (FileInfo, error) {

	hash, err := computeHash(fileInfo.Path)
	if err != nil {
		fmt.Printf("Failed to compute hash for file %s: %s\n", fileInfo.Path, err)
		return fileInfo, err
	}
	fileInfo.Hash = hash
	isText, numberOfLines := ifTextCountLinesInFile(fileInfo.Path)
	fileInfo.IsText = isText
	fileInfo.NumberOfLines = numberOfLines

	return fileInfo, nil
}

func computeHash(path string) (string, error) {

	content, err := ioutil.ReadFile(path)
	if err != nil {
		return "", err
	}
	hash := sha256.Sum256(content)
	return "sha256:" + hex.EncodeToString(hash[:]), nil
}

func ifTextCountLinesInFile(path string) (bool, int) {

	f, err := os.Open(path)
	if err != nil {
		return false, 0
	}
	defer f.Close()

	return ifTextCountLines(f)
}

func ifTextCountLines(r io.Reader) (bool, int) {

	scanner := bufio.NewScanner(r)
	numberOfLines := 0
	for scanner.Scan() {
		line := scanner.Text()
		for _, r := range line {
			if !unicode.IsGraphic(r) && !unicode.IsSpace(r) {
				return false, 0
			}
		}
		if len(strings.TrimSpace(line)) > 0 {
			numberOfLines++
		}
	}
	if err := scanner.Err(); err != nil {
		return false, 0
	}

	return true, numberOfLines
}

func computeMatch(path1, path2 string) (int, error) {

	content1, err := ioutil.ReadFile(path1)
	if err != nil {
		return 0, err
	}
	content2, err := ioutil.ReadFile(path2)
	if err != nil {
		return 0, err
	}

	return levenshtein.ComputeDistance(string(content1), string(content2)), nil
}

func printAsJson(result Result) {

	outputJson, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		fmt.Printf("Failed to create JSON: %s\n", err)
		return
	}

	fmt.Println(string(outputJson))
}
