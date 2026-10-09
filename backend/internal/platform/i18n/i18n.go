// Package i18n holds text that exists in both product languages (PRD §11).
package i18n

// Language is a supported UI language code.
type Language string

// Supported languages.
const (
	English Language = "en"
	Bangla  Language = "bn"
)

// Text is a value in English and Bangla.
type Text struct {
	EN string
	BN string
}
