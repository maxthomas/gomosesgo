package main

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"unicode"

	"golang.org/x/text/transform"
)

// TransformCommand is an interface for different kinds of processing transforms
type TransformCommand interface {
	Execute(string, *TranslationTransformer) (string, error)
}

// ExecTransformCommand represents an external command on strings
type ExecTransformCommand struct {
	Args                 []string
	Command              string
	AppendPathToCmd      bool
	AppendPathToFirstArg bool
}

// FilterTransformCommand does simple filtering
type FilterTransformCommand struct {
	removeNewlines bool
	collapseSpaces bool
	removeEmoji    bool
}

var (
	// TCTagString runs the external string tagger
	TCTagString = ExecTransformCommand{Command: "perl", Args: []string{"pretag-twitter-zone.perl", "-b", "-protected", "bin/tag-fixed-twitter-protected-patterns"}, AppendPathToFirstArg: true}
	// TCTokenizeString runs the external tokenizer
	TCTokenizeString = ExecTransformCommand{Command: "perl", Args: []string{"moses_proc_zone.perl"}, AppendPathToFirstArg: true}
	// TCRejoinString runs the external hashtag rejoiner
	TCRejoinString = ExecTransformCommand{Command: "perl", Args: []string{"rejoin-hashtags.perl"}, AppendPathToFirstArg: true}
	// TCDetokenizeString runs the external detokenizer
	TCDetokenizeString = ExecTransformCommand{Command: "perl", Args: []string{"detokenizer.perl", "-b", "-l", "en"}, AppendPathToFirstArg: true}

	collapseSpaceRegex1 = regexp.MustCompile("\\s\\s+")
	collapseSpaceRegex2 = regexp.MustCompile("\\s([\\',.])")
)

// Execute the FTC command
func (ftc FilterTransformCommand) Execute(in string, tf *TranslationTransformer) (string, error) {
	out := in
	if ftc.removeEmoji {
		input := []byte(out)
		b := make([]byte, len(input))

		t := transform.RemoveFunc(unicode.IsSymbol)
		n, _, _ := t.Transform(b, input, true)
		out = string(b[:n])
	}
	if ftc.removeNewlines {
		out = strings.Replace(out, "\r\n", " ", -1)
		out = strings.Replace(out, "\n", " ", -1)
	}
	if ftc.collapseSpaces {
		out = collapseSpaceRegex1.ReplaceAllString(out, " ")
		out = collapseSpaceRegex2.ReplaceAllString(out, "$1")
	}
	return out, nil
}

func (tc *ExecTransformCommand) getCommand(basePath string) string {
	var cmd string
	if tc.Command != "" {
		cmd = tc.Command
	} else {
		cmd = tc.Args[0]
	}
	if tc.AppendPathToCmd {
		cmd = filepath.Join(basePath, cmd)
	}
	return cmd
}

func (tc *ExecTransformCommand) getArgs(basePath string) []string {
	var args []string
	if tc.Command != "" {
		args = tc.Args
	} else {
		args = tc.Args[1:]
	}

	t := make([]string, len(args), len(args))
	copy(t, args)
	if tc.AppendPathToFirstArg {
		t[0] = filepath.Join(basePath, args[0])
	}
	return t
}

// TranslationTransformer is an object w/ methods for pre and post processing
// of strings for translation
type TranslationTransformer struct {
	LibPath            string
	PreprocessMethods  []TransformCommand
	PostprocessMethods []TransformCommand
}

// NewTranslationTransformer returns a TranslationTransformer object. Requires
// the path to supporting library executables
func NewTranslationTransformer(libPath string) (TranslationTransformer, error) {
	tf := TranslationTransformer{
		PreprocessMethods:  []TransformCommand{TCTagString, TCTokenizeString, FilterTransformCommand{removeEmoji: true}},
		PostprocessMethods: []TransformCommand{TCRejoinString, TCDetokenizeString, FilterTransformCommand{removeNewlines: true, collapseSpaces: true}}}
	var err error
	tf.LibPath, err = filepath.Abs(libPath)
	return tf, err
}

// Preprocess the input text so that it may be run through translation
func (tf *TranslationTransformer) Preprocess(in string) (string, error) {
	pre := strings.TrimSpace(in)
	return tf.execCommands(tf.PreprocessMethods, pre)
}

// Postprocess the input text so that it may be run through translation
func (tf *TranslationTransformer) Postprocess(in string) (string, error) {
	return tf.execCommands(tf.PostprocessMethods, in)
}

func (tf *TranslationTransformer) execCommands(commands []TransformCommand, in string) (string, error) {
	var err error
	pre := in
	for _, cmd := range commands {
		pre, err = cmd.Execute(pre, tf)
		if err != nil {
			return "", fmt.Errorf("command errored with: %s", err.Error())
		}
	}
	return pre, nil
}

// Execute runs the ExecTransformCommand
func (tc ExecTransformCommand) Execute(in string, tf *TranslationTransformer) (string, error) {
	var cmdOut []byte
	var err error

	subprocess := exec.Command(tc.getCommand(tf.LibPath), tc.getArgs(tf.LibPath)...)
	stdin, err := subprocess.StdinPipe()
	if err != nil {
		return "", err
	}
	stdin.Write([]byte(in))
	stdin.Close()
	if cmdOut, err = subprocess.Output(); err != nil {
		return "", err
	}
	return string(cmdOut), nil
}
