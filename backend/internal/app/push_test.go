package app

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"os"
	"path/filepath"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/push"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

func credentialsFile(t *testing.T) string {
	t.Helper()
	key, _ := rsa.GenerateKey(rand.Reader, 2048)
	der, _ := x509.MarshalPKCS8PrivateKey(key)
	raw, _ := json.Marshal(map[string]string{"type": "service_account", "project_id": "pao-test", "client_email": "push@pao-test.iam.gserviceaccount.com",
		"private_key": string(pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: der})), "token_uri": "https://oauth2.googleapis.com/token"})
	path := filepath.Join(t.TempDir(), "fcm.json")
	if err := os.WriteFile(path, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestPushAdapter_ChosenByConfig(t *testing.T) {
	m := &Modules{}
	got, err := pushAdapter(&Infra{Config: config.Config{PushAdapter: "console"}, Log: logx.Discard()}, m)
	if _, ok := got.(*push.Capture); !ok || err != nil || m.PushCapture == nil {
		t.Fatalf("console: %T %v", got, err)
	}
	got, err = pushAdapter(&Infra{Config: config.Config{PushAdapter: "fcm", FCMCredentialsFile: credentialsFile(t)}}, &Modules{})
	if _, ok := got.(*push.FCM); !ok || err != nil {
		t.Fatalf("fcm: %T %v", got, err)
	}
}

func TestBuildModules_RejectsMissingPushCredentials(t *testing.T) {
	cfg := config.Config{DataEncryptionKey: make([]byte, 32), PushAdapter: "fcm", FCMCredentialsFile: filepath.Join(t.TempDir(), "absent.json")}
	if _, err := BuildModules(&Infra{Config: cfg, Log: logx.Discard()}); err == nil {
		t.Fatal("missing credentials accepted")
	}
}
