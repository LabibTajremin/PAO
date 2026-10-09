package app

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
)

// CheckPhoneCode verifies a code sent with SendCode for a purpose other than login,
// such as confirming a provider's emergency contact (PRD §6.2 item 6).
func (s *Service) CheckPhoneCode(ctx context.Context, rawPhone, purpose, code string) error {
	phone, err := domain.NormalizePhone(rawPhone)
	if err != nil {
		return err
	}
	return s.checkCode(ctx, purpose, phone, code)
}
