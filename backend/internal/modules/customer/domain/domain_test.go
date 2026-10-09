package domain

import (
	"errors"
	"strings"
	"testing"
)

var banani = Point{Lat: 23.7937, Lng: 90.4066}

func TestCustomerValidate(t *testing.T) {
	for _, c := range []Customer{{Name: "N", Language: "bn"}, {Name: strings.Repeat("ন", 81), Language: "bn"}, {Name: "Nusrat", Language: "fr"}} {
		if !errors.Is(c.Validate(), ErrInvalid) {
			t.Errorf("%+v accepted", c)
		}
	}
	if err := (Customer{Name: "নুসরাত", Language: "bn"}).Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestAddressValidate(t *testing.T) {
	ok := Address{Label: "home", Line1: "House 12, Road 5", Location: banani}
	if err := ok.Validate(); err != nil {
		t.Fatal(err)
	}
	bad := []Address{
		{Label: "farm", Line1: ok.Line1, Location: banani},
		{Label: "home", Line1: "ab", Location: banani},
		{Label: "home", Line1: ok.Line1, Line2: strings.Repeat("x", 201), Location: banani},
		{Label: "home", Line1: ok.Line1, Area: strings.Repeat("x", 81), Location: banani},
	}
	for _, a := range bad {
		if !errors.Is(a.Validate(), ErrInvalid) {
			t.Errorf("%+v accepted", a)
		}
	}
	swapped := Address{Label: "home", Line1: ok.Line1, Location: Point{Lat: banani.Lng, Lng: banani.Lat}}
	if !errors.Is(swapped.Validate(), ErrOutsideCountry) {
		t.Fatal("swapped coordinates accepted")
	}
}

const square = `{"type":"Polygon","coordinates":[[[90,23],[91,23],[91,24],[90,24],[90,23]],[[90.5,23.5],[90.6,23.5],[90.6,23.6],[90.5,23.6],[90.5,23.5]]]}`

func TestCovers(t *testing.T) {
	cases := []struct {
		area string
		p    Point
		want bool
	}{
		{"", banani, true},
		{square, banani, true},
		{square, Point{Lat: 23.55, Lng: 90.55}, false},
		{square, Point{Lat: 22, Lng: 90.5}, false},
		{`{"type":"MultiPolygon","coordinates":[[[[88,22],[89,22],[89,23],[88,22]]],[[[90,23],[91,23],[91,24],[90,24],[90,23]]]]}`, banani, true},
		{`{"type":"Polygon","coordinates":[]}`, banani, false},
		{`{"type":"Point","coordinates":[90,23]}`, banani, false},
		{"{", banani, false},
	}
	for i, c := range cases {
		if got := Covers(c.area, c.p); got != c.want {
			t.Errorf("case %d: Covers = %v", i, got)
		}
	}
}
