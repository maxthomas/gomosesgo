package main

import "testing"

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
