package api

import (
	"bytes"
	"fmt"
	"hash/fnv"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sync"
	"testing"
	"time"
)

var codePattern = regexp.MustCompile(`[0-9]{6}`)

// lastCode reads the newest one-time code texted to phone from the SMS capture.
func lastCode(t *testing.T, phone string) string {
	t.Helper()
	r := call(t, stack.api, "GET", "/__test/sms?phone="+url.QueryEscape(phone), nil, session{})
	if r.Status != http.StatusOK {
		t.Fatalf("no sms to %s: %d", phone, r.Status)
	}
	return codePattern.FindString(r.JSON(t)["message"].(string))
}

// deviceOf is the address phone's device connects from, stable per phone.
func deviceOf(phone string) session {
	h := fnv.New32a()
	_, _ = h.Write([]byte(phone))
	n := h.Sum32()
	return session{IP: fmt.Sprintf("198.18.%d.%d", n>>8&0xff, n&0xff)}
}

// requestCode asks for a login code from phone's device.
func requestCode(t *testing.T, phone string) response {
	t.Helper()
	return do(t, "POST", "/v1/auth/otp/request", map[string]string{"phone": phone, "purpose": "login"}, deviceOf(phone))
}

// signIn requests and enters a one-time code; app is "customer" or "partner".
func signIn(t *testing.T, phone, app string) session {
	t.Helper()
	if r := requestCode(t, phone); r.Status != http.StatusAccepted {
		t.Fatalf("code for %s: %d %s", phone, r.Status, r.Body)
	}
	dev := deviceOf(phone)
	tp := must(t, 200, "POST", "/v1/auth/otp/verify",
		map[string]string{"phone": phone, "code": lastCode(t, phone), "app": app}, dev)
	return session{ID: tp["account"].(map[string]any)["id"].(string), Token: tp["accessToken"].(string), IP: dev.IP}
}

// customer signs a new customer up with a profile and a default address in Banani.
func customer(t *testing.T, phone string) session {
	t.Helper()
	c, _ := customerAt(t, phone)
	return c
}

// customerAt is customer that also returns the saved address's ID, for bookings.
func customerAt(t *testing.T, phone string) (session, string) {
	t.Helper()
	c := signIn(t, phone, "customer")
	must(t, 200, "PUT", "/v1/customer/profile", map[string]string{"name": "Nusrat Jahan", "language": "en"}, c)
	a := must(t, 201, "POST", "/v1/customer/addresses", map[string]any{"label": "home", "line1": "House 12, Road 5, Banani",
		"location": map[string]float64{"lat": 23.7940, "lng": 90.4070}, "isDefault": true}, c)
	return c, a["id"].(string)
}

// upload stores a small confirmed image through the signed URL, as an app would;
// role is "customer" or "provider".
func upload(t *testing.T, s session, role, purpose string) string {
	t.Helper()
	body := []byte("e2e-image")
	ticket := must(t, 201, "POST", "/v1/"+role+"/uploads",
		map[string]any{"purpose": purpose, "contentType": "image/jpeg", "sizeBytes": len(body)}, s)
	req, _ := http.NewRequestWithContext(t.Context(), http.MethodPut, ticket["uploadUrl"].(string), bytes.NewReader(body))
	for k, v := range ticket["headers"].(map[string]any) {
		req.Header.Set(k, v.(string))
	}
	res, err := httpClient.Do(req)
	if err != nil || res.StatusCode != http.StatusOK {
		t.Fatalf("put %s: %v %v", purpose, res, err)
	}
	_ = res.Body.Close()
	id := ticket["mediaId"].(string)
	must(t, 200, "POST", "/v1/"+role+"/uploads/"+id+"/confirm", nil, s)
	return id
}

var admins = struct {
	sync.Mutex
	token map[string]string
}{token: map[string]string{}}

// secretsFile keeps the admins' authenticator secrets across runs against one stack:
// TOTP enrolment happens only on an admin's first sign-in. stack.sh removes it.
var secretsFile = filepath.Join("..", ".admins.env")

// admin signs a seeded admin in with password and authenticator code, enrolling TOTP
// on the first sign-in, and reuses the session for the rest of the run.
func admin(t *testing.T, email string) session {
	t.Helper()
	admins.Lock()
	defer admins.Unlock()
	if tok, ok := admins.token[email]; ok {
		return session{Token: tok}
	}
	secrets, _ := readEnv(secretsFile)
	if secrets == nil {
		secrets = map[string]string{}
	}
	ch := must(t, 200, "POST", "/v1/auth/admin/login", map[string]string{"email": email, "password": stack.adminPassword}, session{})
	if enrol, ok := ch["totpEnrolment"].(map[string]any); ok {
		secrets[email] = enrol["secret"].(string)
		appendSecret(t, email, secrets[email])
	}
	body := map[string]string{"challengeId": ch["challengeId"].(string), "code": totp(secrets[email], time.Now())}
	r := do(t, "POST", "/v1/auth/admin/totp", body, session{})
	if r.Status != http.StatusOK {
		// A code is accepted once; a run right after the last one waits for the next.
		time.Sleep(time.Until(time.Now().Truncate(30 * time.Second).Add(31 * time.Second)))
		body["code"] = totp(secrets[email], time.Now())
		r = do(t, "POST", "/v1/auth/admin/totp", body, session{})
	}
	if r.Status != http.StatusOK {
		t.Fatalf("admin %s totp: %d %s", email, r.Status, r.Body)
	}
	admins.token[email] = r.JSON(t)["accessToken"].(string)
	return session{Token: admins.token[email]}
}

func appendSecret(t *testing.T, email, secret string) {
	t.Helper()
	f, err := os.OpenFile(secretsFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = f.Close() }()
	_, _ = fmt.Fprintf(f, "%s=%s\n", email, secret)
}

// phoneFor gives each test its own Bangladeshi mobile number.
func phoneFor(t *testing.T, prefix string, n int) string {
	t.Helper()
	return fmt.Sprintf("%s%08d", prefix, (time.Now().UnixNano()/1000+int64(n))%100_000_000)
}
