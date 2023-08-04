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
	Size          int64     `json:"size"`
	Date          time.Time `json:"date"`
	Hash          string    `json:"hash"`
	IsText        bool      `json:"isText"`
	NumberOfLines int       `json:"numberOfLines"`
}

type TextFileComparisonInfo struct {
	Exists bool `json:"exists"`
	Match  int  `json:"match"`
}

type Result struct {
	Source      map[string]FileInfo               `json:"source"`
	Destination map[string]FileInfo               `json:"destination"`
	Comparison  map[string]TextFileComparisonInfo `json:"comparison"`
}

func main() {

	args, err := parseArguments()
	if err != nil {
		log.Fatalf("Error while parsing the command-line arguments: %s\n", err)
	}

	config, err := readConfig(*args.Cfg)
	if err != nil {
		log.Fatalf("Error while reading the config file: %s\n", err)
	}

	ignore := CompileIgnoreLines(config.Update.Ignore...)

	source, destination, err := walk(args.Dir1, args.Dir2, ignore)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	result := compare(source, destination)
	printAsJson(result)
}

func walk(dir1, dir2 *string, ignore *GitIgnore) (map[string]FileInfo, map[string]FileInfo, error) {

	source := make(map[string]FileInfo)
	destination := make(map[string]FileInfo)

	err := filepath.Walk(*dir1, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			file, _ := filepath.Rel(*dir1, path)
			if file == "." {
				return nil
			}
			if ignore.MatchesPath(file) {
				return nil
			}
			absPath, _ := filepath.Abs(path)
			source[file] = FileInfo{
				Path: absPath,
				Size: info.Size(),
				Date: info.ModTime(),
			}
		}
		return nil
	})
	if err != nil {
		return nil, nil, err
	}

	err = filepath.Walk(*dir2, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			file, _ := filepath.Rel(*dir2, path)
			if file == "." {
				return nil
			}
			if ignore.MatchesPath(file) {
				return nil
			}
			absPath, _ := filepath.Abs(path)
			destination[file] = FileInfo{
				Path: absPath,
				Size: info.Size(),
				Date: info.ModTime(),
			}
		}
		return nil
	})
	if err != nil {
		return nil, nil, err
	}

	return source, destination, nil
}

func compare(source, destination map[string]FileInfo) Result {

	comparison := make(map[string]TextFileComparisonInfo)

	for file, info1 := range source {
		source[file], _ = populateInfo(info1)
		if info2, exists := destination[file]; exists {
			destination[file], _ = populateInfo(info2)

			levenshteinDistance, err := computeMatch(info1.Path, info2.Path)
			if err != nil {
				fmt.Printf("Failed to compare file %s: %s\n", file, err)
				continue
			}
			match := 100 - int(float64(levenshteinDistance)/float64(info1.Size)*100)
			comparison[file] = TextFileComparisonInfo{
				Exists: true,
				Match:  match,
			}
		} else {
			comparison[file] = TextFileComparisonInfo{
				Exists: false,
				Match:  0,
			}
		}
	}
	for file, info := range destination {
		if _, exists := source[file]; !exists {
			destination[file], _ = populateInfo(info)
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
