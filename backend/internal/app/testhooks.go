package app

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
)

// WithTestHooks adds the /__test/ endpoints end-to-end journeys use to read what the
// fake SMS and push adapters captured and to run the expiry sweep on demand. Outside
// APP_ENV=test it returns next unchanged, so the hooks never exist in production.
func WithTestHooks(next http.Handler, i *Infra, m *Modules) http.Handler {
	if i.Config.AppEnv != config.EnvTest {
		return next
	}
	mux := http.NewServeMux()
	mux.Handle("/", next)
	mux.HandleFunc("GET /__test/sms", func(w http.ResponseWriter, r *http.Request) { lastSMS(w, r, m) })
	mux.HandleFunc("GET /__test/pushes", func(w http.ResponseWriter, r *http.Request) { pushesTo(w, r, m) })
	mux.HandleFunc("POST /__test/verification/expire", func(w http.ResponseWriter, r *http.Request) { expireAt(w, r, m) })
	return mux
}

func lastSMS(w http.ResponseWriter, r *http.Request, m *Modules) {
	phone, err := domain.NormalizePhone(r.URL.Query().Get("phone"))
	if err != nil {
		http.Error(w, "bad phone", http.StatusBadRequest)
		return
	}
	msg := ""
	if m.SMSCapture != nil {
		msg = m.SMSCapture.Last(phone)
	}
	if msg == "" {
		http.NotFound(w, r)
		return
	}
	writeJSON(w, map[string]string{"message": msg})
}

type sentPush struct {
	Title string            `json:"title"`
	Body  string            `json:"body"`
	Data  map[string]string `json:"data"`
}

func pushesTo(w http.ResponseWriter, r *http.Request, m *Modules) {
	out := []sentPush{}
	if m.PushCapture != nil {
		for _, s := range m.PushCapture.To(r.URL.Query().Get("token")) {
			out = append(out, sentPush{Title: s.Push.Title, Body: s.Push.Body, Data: s.Push.Data})
		}
	}
	writeJSON(w, map[string]any{"pushes": out})
}

func expireAt(w http.ResponseWriter, r *http.Request, m *Modules) {
	at, err := time.Parse(time.RFC3339, r.URL.Query().Get("at"))
	if err != nil {
		http.Error(w, "at must be RFC 3339", http.StatusBadRequest)
		return
	}
	if err := m.Verification.Service.ExpireDocumentsAt(r.Context(), at.UTC()); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
