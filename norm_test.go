package main

import (
	"reflect"
	"testing"
)

func TestRemoveEmoji(t *testing.T) {
	input := `@saleh_juventino \n\nتحرك هيغواين جداً جميل سحب المدافع معاه 😍😍`
	output := `@saleh_juventino \n\nتحرك هيغواين جداً جميل سحب المدافع معاه `

	filter := FilterTransformCommand{removeEmoji: true}

	filtered, _ := filter.Execute(input, nil)
	if filtered != output {
		t.Error("emoji not filtered.")
		t.Log("Expected: ", output)
		t.Log("Actual:   ", filtered)
		t.FailNow()
	}
}

func TestGetHashtags(t *testing.T) {
	var tests = []struct {
		input  string
		output []string
	}{
		{"", []string{}},
		{"input with no hashtags at all! what a bummer", []string{}},
		{"input with #single hashtag", []string{"single"}},
		{"multiple #hashtag #nofilter #yolo", []string{"hashtag", "nofilter", "yolo"}},
	}
	for testNo, test := range tests {
		actual := getHashtags(test.input)
		if len(test.output) == len(actual) && len(actual) == 0 {
			continue
		}
		if len(actual) != len(test.output) && !reflect.DeepEqual(test.output, actual) {
			t.Error("Unexpected hashtag output, testno:", testNo)
			t.Error("Expected:", test.output)
			t.Error("Actual:", actual)
			t.FailNow()
		}
	}
}
