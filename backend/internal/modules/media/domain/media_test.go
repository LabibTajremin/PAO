package domain

import (
	"errors"
	"testing"

	"github.com/google/uuid"
)

func TestCheckUpload(t *testing.T) {
	cases := []struct {
		uploader, purpose, ct string
		size                  int64
		want                  error
	}{
		{"provider", "nid_front", "image/jpeg", 1000, nil},
		{"provider", "police_clearance", "application/pdf", 5 * mb, nil},
		{"provider", "selfie", "application/pdf", 1000, ErrInvalid},
		{"customer", "avatar", "image/png", 2*mb + 1, ErrInvalid},
		{"customer", "avatar", "image/png", 0, ErrInvalid},
		{"customer", "nid_front", "image/png", 10, ErrForbidden},
		{"admin", "level2_photo", "image/png", 10, nil},
		{"stranger", "avatar", "image/png", 10, ErrForbidden},
	}
	for _, c := range cases {
		if err := CheckUpload(c.uploader, c.purpose, c.ct, c.size); !errors.Is(err, c.want) {
			t.Errorf("%+v: %v", c, err)
		}
	}
	if r, ok := RuleFor("nid_back"); !ok || !r.Sensitive {
		t.Fatal("nid is sensitive")
	}
	if r, _ := RuleFor("avatar"); r.Sensitive {
		t.Fatal("avatar is not sensitive")
	}
	o, id := uuid.New(), uuid.New()
	if ObjectKey("selfie", o, id) != "selfie/"+o.String()+"/"+id.String() {
		t.Fatal("key")
	}
}
