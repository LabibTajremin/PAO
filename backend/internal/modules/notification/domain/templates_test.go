package domain

import (
	"errors"
	"strings"
	"testing"
)

func TestRender(t *testing.T) {
	en, err := Render("booking_accepted", "en", map[string]string{"provider": "Rahim", "number": "PAO-100001"})
	if err != nil || en.Body != "Rahim accepted booking PAO-100001." {
		t.Fatalf("en: %+v %v", en, err)
	}
	bn, _ := Render("booking_accepted", "bn", map[string]string{"provider": "রহিম", "number": "PAO-100001"})
	if !strings.Contains(bn.Body, "রহিম") || bn.Title != "বুকিং গৃহীত" {
		t.Fatalf("bn: %+v", bn)
	}
	if _, err := Render("nope", "en", nil); !errors.Is(err, ErrUnknownTemplate) {
		t.Fatal(err)
	}
}

func TestTemplatesAreComplete(t *testing.T) {
	for name, tmpl := range Templates {
		for _, x := range []Text{tmpl.EN, tmpl.BN} {
			if x.Title == "" || x.Body == "" {
				t.Errorf("%s has an empty text", name)
			}
		}
		if strings.Count(tmpl.EN.Body, "{{") != strings.Count(tmpl.BN.Body, "{{") {
			t.Errorf("%s: languages use different placeholders", name)
		}
	}
}
