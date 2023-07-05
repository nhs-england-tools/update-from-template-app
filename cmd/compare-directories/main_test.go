package main

import (
	"io/ioutil"
	"os"
	"strings"
	"testing"
)

func TestParseArguments(t *testing.T) {

	t.Run("it should parse dir1 and dir2", func(t *testing.T) {
		// Arrange
		os.Args = []string{"cmd", "-dir1=path1", "-dir2=path2"}
		// Act
		args := parseArguments()
		// Assert
		if *args.Dir1 != "path1" {
			t.Errorf("Expected Dir1 to be 'path1', got '%s'", *args.Dir1)
		}
		if *args.Dir2 != "path2" {
			t.Errorf("Expected Dir2 to be 'path2', got '%s'", *args.Dir2)
		}
	})

	t.Run("it should parse exclude", func(t *testing.T) {
		// Arrange
		os.Args = []string{"cmd", "-dir1=path1", "-dir2=path2", "-exclude=path3"}
		// Act
		args := parseArguments()
		// Assert
		if *args.Exclude != "path3" {
			t.Errorf("Expected Exclude to be 'path3', got '%s'", *args.Exclude)
		}
	})
}

func TestPopulateInfo(t *testing.T) {

	// Arrange
	tempFile, err := ioutil.TempFile("", "test")
	if err != nil {
		t.Fatalf("Failed to create temp file: %s", err)
	}
	defer os.Remove(tempFile.Name())
	content := "Hello\nWorld\n"
	if _, err := tempFile.Write([]byte(content)); err != nil {
		t.Fatalf("Failed to write to temp file: %s", err)
	}
	tempFileInfo := FileInfo{Path: tempFile.Name()}
	// Act
	updatedInfo, err := populateInfo(tempFileInfo)
	if err != nil {
		t.Fatalf("populateInfo failed: %s", err)
	}
	// Assert
	if !updatedInfo.IsText {
		t.Errorf("Expected IsText to be true, but it was false")
	}
	expectedLines := strings.Count(content, "\n")
	if updatedInfo.NumberOfLines != expectedLines {
		t.Errorf("Expected NumberOfLines to be %d, but it was %d", expectedLines, updatedInfo.NumberOfLines)
	}
}

func TestComputeHash(t *testing.T) {

	// Arrange
	tempFile, err := ioutil.TempFile("", "tempFile")
	if err != nil {
		t.Fatalf("Could not create temp file: %v", err)
	}
	defer os.Remove(tempFile.Name())
	_, err = tempFile.Write([]byte("Hello, World!"))
	if err != nil {
		t.Fatalf("Could not write to temp file: %v", err)
	}
	// Act
	hash, err := computeHash(tempFile.Name())
	// Assert
	expectedHash := "sha256:dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f"
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	} else if hash != expectedHash {
		t.Errorf("Expected hash %s, but got %s", expectedHash, hash)
	}
}

func TestIfTextCountLines(t *testing.T) {

	// Arrange
	tests := []struct {
		name          string
		input         string
		isText        bool
		numberOfLines int
	}{
		{"empty", "", true, 0},
		{"one line no spaces", "abc", true, 1},
		{"two lines", "abc\ndef", true, 2},
		{"multiple line text", "Line 1\nLine 2\nLine 3", true, 3},
		{"empty lines", "\n\n\n", true, 0},
		{"non-text character", "abc\x00def", false, 0},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			// Act
			isText, numberOfLines := ifTextCountLines(strings.NewReader(test.input))
			// Assert
			if isText != test.isText {
				t.Errorf("expected isText %v, got %v", test.isText, isText)
			}
			if numberOfLines != test.numberOfLines {
				t.Errorf("expected numLines %v, got %v", test.numberOfLines, numberOfLines)
			}
		})
	}
}

func TestComputeMatch(t *testing.T) {

	// Arrange
	file1, err := ioutil.TempFile("", "test1")
	if err != nil {
		t.Fatalf("Failed to create temp file: %s", err)
	}
	defer os.Remove(file1.Name())
	file2, err := ioutil.TempFile("", "test2")
	if err != nil {
		t.Fatalf("Failed to create temp file: %s", err)
	}
	defer os.Remove(file2.Name())
	content1 := "Hello World"
	content2 := "Ello World!"
	if _, err := file1.Write([]byte(content1)); err != nil {
		t.Fatalf("Failed to write to temp file: %s", err)
	}
	if _, err := file2.Write([]byte(content2)); err != nil {
		t.Fatalf("Failed to write to temp file: %s", err)
	}
	// Act
	distance, err := computeMatch(file1.Name(), file2.Name())
	if err != nil {
		t.Fatalf("computeMatch failed: %s", err)
	}
	// Assert
	expectedDistance := 3
	if distance != expectedDistance {
		t.Fatalf("Expected distance of %d, but got %d", expectedDistance, distance)
	}
}
