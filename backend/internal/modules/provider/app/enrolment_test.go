package app

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
)

var dhaka = domain.Point{Lat: 23.79, Lng: 90.41}

func personal(f fixture) domain.Personal {
	return domain.Personal{FullName: " Rahim Uddin ", DateOfBirth: f.clock.Now().AddDate(-30, 0, 0), Gender: "male",
		PresentAddress: "Banani 11", PermanentAddress: "Cumilla Sadar"}
}

func TestEnrolment_AllStepsThenSubmit(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	id := uuid.New()
	if p, err := f.svc.Enrolment(ctx, id); err != nil || p.Complete || len(p.Steps) != 9 {
		t.Fatalf("fresh: %+v %v", p, err)
	}
	if _, err := f.svc.SavePersonal(ctx, id, personal(f)); err != nil {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveServices(ctx, id, []uuid.UUID{f.electric}, 8); err != nil {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveArea(ctx, id, dhaka, 8000); err != nil {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveEmergencyContact(ctx, id, domain.EmergencyContact{Name: "Karim", Relation: "Brother", Phone: "01812345678"}); err != nil {
		t.Fatal(err)
	}
	if len(f.peers.sent) != 1 || f.peers.sent[0] != "+8801812345678" {
		t.Fatalf("code sent to %v", f.peers.sent)
	}
	if _, err := f.svc.VerifyEmergencyContact(ctx, id, "123456"); err != nil {
		t.Fatal(err)
	}
	if _, err := f.svc.AcceptCodeOfConduct(ctx, id, "2026-10", true); err != nil {
		t.Fatal(err)
	}
	if err := f.svc.MarkSubmitted(ctx, id); !errors.Is(err, domain.ErrIncomplete) {
		t.Fatal("submitted without documents")
	}
	for _, s := range []string{"nid", "selfie", "police_clearance"} {
		if _, err := f.svc.MarkStepDone(ctx, id, s); err != nil {
			t.Fatal(err)
		}
	}
	if err := f.svc.MarkSubmitted(ctx, id); err != nil {
		t.Fatal(err)
	}
	p, _ := f.svc.Enrolment(ctx, id)
	if !p.Complete || !p.Submitted {
		t.Fatalf("progress: %+v", p)
	}
	saved := 0
	for _, e := range f.repo.events {
		if _, ok := e.(contract.EnrolmentStepSaved); ok {
			saved++
		}
	}
	if got := f.repo.rows[id]; saved != 5 || got.FullName != "Rahim Uddin" || got.Emergency.VerifiedAt == nil || got.CoCAcceptedAt == nil {
		t.Fatalf("saved %d, row %+v", saved, got)
	}
	if _, err := f.svc.SaveEmergencyContact(ctx, id, domain.EmergencyContact{Name: "Karim", Relation: "Brother", Phone: "01912345678"}); err != nil {
		t.Fatal(err)
	}
	if p, _ := f.svc.Enrolment(ctx, id); p.Complete {
		t.Fatal("new emergency contact kept the step done")
	}
	f.peers.codeErr = domain.ErrCodeRejected
	if _, err := f.svc.VerifyEmergencyContact(ctx, id, "000000"); !errors.Is(err, domain.ErrCodeRejected) {
		t.Fatal(err)
	}
}

func TestEnrolment_Rejections(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	id := uuid.New()
	young := personal(f)
	young.DateOfBirth = f.clock.Now().AddDate(-17, 0, 0)
	if _, err := f.svc.SavePersonal(ctx, id, young); !errors.Is(err, domain.ErrTooYoung) {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveServices(ctx, id, nil, 1); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveServices(ctx, id, []uuid.UUID{uuid.New()}, 1); !errors.Is(err, domain.ErrUnknownService) {
		t.Fatal(err)
	}
	hidden := uuid.New()
	f.peers.services[hidden] = port.Service{ID: hidden}
	if _, err := f.svc.SaveServices(ctx, id, []uuid.UUID{hidden}, 1); !errors.Is(err, domain.ErrUnknownService) {
		t.Fatal("unpublished service accepted")
	}
	if _, err := f.svc.SaveArea(ctx, id, dhaka, 10); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveEmergencyContact(ctx, id, domain.EmergencyContact{Name: "K", Relation: "Brother", Phone: "x"}); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	if _, err := f.svc.SaveEmergencyContact(ctx, id, domain.EmergencyContact{Name: "Karim", Relation: "Self", Phone: "01712345678"}); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal("own phone accepted as emergency contact")
	}
	if _, err := f.svc.VerifyEmergencyContact(ctx, id, "1"); !errors.Is(err, domain.ErrContactUnproven) {
		t.Fatal(err)
	}
	if _, err := f.svc.AcceptCodeOfConduct(ctx, id, "2026-10", false); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal(err)
	}
	f.peers.codeErr = domain.ErrCodeRejected
	if _, err := f.svc.SaveEmergencyContact(ctx, id, domain.EmergencyContact{Name: "Karim", Relation: "Brother", Phone: "01812345678"}); err == nil {
		t.Fatal("send failure ignored")
	}
	if _, err := f.svc.VerifyEmergencyContact(ctx, id, "1"); !errors.Is(err, domain.ErrContactUnproven) {
		t.Fatalf("failed send must not save the contact: %v", err)
	}
}

func TestEnrolment_StoreFailures(t *testing.T) {
	f := newFixture()
	ctx := context.Background()
	id := uuid.New()
	f.repo.getErr = errBoom
	if _, err := f.svc.Enrolment(ctx, id); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	if err := f.svc.MarkSubmitted(ctx, id); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.repo.getErr, f.peers.err = nil, errBoom
	if _, err := f.svc.MarkStepDone(ctx, id, "nid"); !errors.Is(err, errBoom) {
		t.Fatal("phone lookup error ignored")
	}
	f.peers.err, f.repo.err = nil, errBoom
	if _, err := f.svc.MarkStepDone(ctx, id, "nid"); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.repo.err = nil
	if _, err := f.svc.MarkStepDone(ctx, id, "nid"); err != nil {
		t.Fatal(err)
	}
	f.repo.err = errBoom
	if _, err := f.svc.MarkStepDone(ctx, id, "selfie"); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
	f.repo.err, f.presence.err = nil, errBoom
	if _, err := f.svc.SaveServices(ctx, id, []uuid.UUID{f.electric}, 1); !errors.Is(err, errBoom) {
		t.Fatal(err)
	}
}
