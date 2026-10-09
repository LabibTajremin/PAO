package domain

import "testing"

func TestEntry_Validate(t *testing.T) {
	if (Entry{Action: "a", SubjectType: "provider", SubjectID: "1"}).Validate() != nil {
		t.Fatal("valid entry refused")
	}
	if (Entry{Action: " ", SubjectType: "provider", SubjectID: "1"}).Validate() == nil {
		t.Fatal("entry without action accepted")
	}
}
