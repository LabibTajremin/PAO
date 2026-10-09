package eventbus

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
)

type pinged struct{ N int }

func (pinged) EventName() string { return "test.Pinged" }

func TestBus_DispatchesToEverySubscriber(t *testing.T) {
	b := NewBus()
	var got []int
	b.Subscribe("test.Pinged", "a", func(_ context.Context, env Envelope) error {
		e, err := Decode[pinged](env)
		got = append(got, e.N)
		return err
	})
	b.Subscribe("test.Pinged", "b", func(context.Context, Envelope) error { return errors.New("down") })
	payload, _ := json.Marshal(pinged{N: 7})
	err := b.Dispatch(context.Background(), Envelope{Name: "test.Pinged", Payload: payload})
	if len(got) != 1 || got[0] != 7 || err == nil || err.Error() != "b: down" {
		t.Fatalf("got %v, err %v", got, err)
	}
	if err := b.Dispatch(context.Background(), Envelope{Name: "test.Nobody"}); err != nil {
		t.Fatalf("no subscribers: %v", err)
	}
	if _, err := Decode[pinged](Envelope{Payload: []byte("{")}); err == nil {
		t.Fatal("bad payload decoded")
	}
}
