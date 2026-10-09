package app

import (
	"context"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/sms"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

func TestSMSAdapter_ChosenByConfig(t *testing.T) {
	cases := map[string]struct {
		cfg  config.Config
		want string
	}{
		"test env":    {config.Config{AppEnv: config.EnvTest, SMSAdapter: "sslwireless"}, "*sms.Capture"},
		"sslwireless": {config.Config{AppEnv: config.EnvProd, SMSAdapter: "sslwireless"}, "sms.SSLWireless"},
		"console":     {config.Config{AppEnv: config.EnvDev, SMSAdapter: "console"}, "sms.Console"},
	}
	for name, tc := range cases {
		m := &Modules{}
		got := smsAdapter(&Infra{Config: tc.cfg, Log: logx.Discard(), IDs: idgen.V7{}}, m)
		var kind string
		switch got.(type) {
		case *sms.Capture:
			kind = "*sms.Capture"
		case sms.SSLWireless:
			kind = "sms.SSLWireless"
		case sms.Console:
			kind = "sms.Console"
		}
		if kind != tc.want {
			t.Errorf("%s: got %T", name, got)
		}
	}
}

func TestBuildModules_RejectsBadDataKey(t *testing.T) {
	if _, err := BuildModules(&Infra{Config: config.Config{DataEncryptionKey: []byte("short")}}); err == nil {
		t.Fatal("short key accepted")
	}
	if got, err := (levelZero{}).GetLevel(context.Background(), [16]byte{}); got != 0 || err != nil {
		t.Fatal("levelZero")
	}
}
