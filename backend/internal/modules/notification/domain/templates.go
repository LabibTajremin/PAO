// Package domain holds notification templates in English and Bangla (C-13, P-12).
package domain

import (
	"errors"
	"strings"
)

// Notification errors.
var (
	ErrNotFound        = errors.New("notification not found")
	ErrUnknownTemplate = errors.New("unknown notification template")
	ErrInvalidToken    = errors.New("device token is no longer valid")
	ErrInvalid         = errors.New("notification request is not valid")
)

// Text is a title and body pair.
type Text struct {
	Title string
	Body  string
}

// Template holds a message in both languages; {{name}} marks a value from the data.
type Template struct {
	EN Text
	BN Text
}

// Templates covers every event that notifies someone (02-architecture.md §8).
var Templates = map[string]Template{
	"booking_requested": {
		EN: Text{"New booking request", "{{service}} in {{area}} — answer before the time runs out."},
		BN: Text{"নতুন বুকিং অনুরোধ", "{{area}}-এ {{service}} — সময় শেষ হওয়ার আগে উত্তর দিন।"}},
	"booking_accepted": {
		EN: Text{"Booking accepted", "{{provider}} accepted booking {{number}}."},
		BN: Text{"বুকিং গৃহীত", "{{provider}} বুকিং {{number}} গ্রহণ করেছেন।"}},
	"booking_rejected": {
		EN: Text{"Provider unavailable", "{{provider}} cannot take booking {{number}}. Please choose another provider."},
		BN: Text{"সেবাদাতা ব্যস্ত", "{{provider}} বুকিং {{number}} নিতে পারছেন না। অনুগ্রহ করে অন্য সেবাদাতা বেছে নিন।"}},
	"booking_timed_out": {
		EN: Text{"No answer yet", "Booking {{number}} was not answered in time. Please choose another provider."},
		BN: Text{"উত্তর পাওয়া যায়নি", "বুকিং {{number}}-এর সময়মতো উত্তর আসেনি। অনুগ্রহ করে অন্য সেবাদাতা বেছে নিন।"}},
	"request_missed": {
		EN: Text{"Request expired", "You did not answer booking {{number}} in time."},
		BN: Text{"অনুরোধের সময় শেষ", "আপনি সময়মতো বুকিং {{number}}-এর উত্তর দেননি।"}},
	"provider_on_the_way": {
		EN: Text{"Provider on the way", "{{provider}} is on the way."},
		BN: Text{"সেবাদাতা আসছেন", "{{provider}} রওনা হয়েছেন।"}},
	"provider_arrived": {
		EN: Text{"Provider arrived", "{{provider}} has arrived. Share your start code to begin."},
		BN: Text{"সেবাদাতা পৌঁছেছেন", "{{provider}} পৌঁছেছেন। কাজ শুরু করতে আপনার স্টার্ট কোড দিন।"}},
	"booking_started": {
		EN: Text{"Job started", "Booking {{number}} is in progress."},
		BN: Text{"কাজ শুরু হয়েছে", "বুকিং {{number}}-এর কাজ চলছে।"}},
	"extras_proposed": {
		EN: Text{"Extra items to approve", "Your provider added items worth ৳{{added}}. Please approve or decline."},
		BN: Text{"অতিরিক্ত আইটেম অনুমোদন", "আপনার সেবাদাতা ৳{{added}} মূল্যের আইটেম যোগ করেছেন। অনুমোদন বা বাতিল করুন।"}},
	"extras_decided": {
		EN: Text{"Customer answered", "The customer {{decision}} the extra items on booking {{number}}."},
		BN: Text{"গ্রাহকের উত্তর", "গ্রাহক বুকিং {{number}}-এর অতিরিক্ত আইটেম {{decision}}।"}},
	"booking_completed": {
		EN: Text{"Job complete", "Booking {{number}} is complete. Please rate your experience."},
		BN: Text{"কাজ সম্পন্ন", "বুকিং {{number}} সম্পন্ন হয়েছে। আপনার অভিজ্ঞতা মূল্যায়ন করুন।"}},
	"booking_cancelled": {
		EN: Text{"Booking cancelled", "Booking {{number}} was cancelled."},
		BN: Text{"বুকিং বাতিল", "বুকিং {{number}} বাতিল করা হয়েছে।"}},
	"level_changed": {
		EN: Text{"Verification updated", "Your verification level is now {{level}}."},
		BN: Text{"যাচাই হালনাগাদ", "আপনার যাচাই স্তর এখন {{level}}।"}},
	"document_rejected": {
		EN: Text{"Document needs attention", "Your {{item}} was not approved: {{reason}}"},
		BN: Text{"নথি ঠিক করুন", "আপনার {{item}} অনুমোদিত হয়নি: {{reason}}"}},
	"document_expired": {
		EN: Text{"Document expired", "Your {{item}} has expired. Renew it to receive bookings again."},
		BN: Text{"নথির মেয়াদ শেষ", "আপনার {{item}}-এর মেয়াদ শেষ। আবার বুকিং পেতে নবায়ন করুন।"}},
	"document_expiring": {
		EN: Text{"Document expiring soon", "Your {{item}} expires in {{days}} days."},
		BN: Text{"নথির মেয়াদ শেষ হতে চলেছে", "আপনার {{item}}-এর মেয়াদ {{days}} দিনের মধ্যে শেষ হবে।"}},
	"level2_scheduled": {
		EN: Text{"Skill check scheduled", "Your Level 2 session is at {{location}} on {{when}}."},
		BN: Text{"দক্ষতা যাচাই নির্ধারিত", "আপনার লেভেল ২ সেশন {{when}} তারিখে {{location}}-এ।"}},
	"complaint_resolved": {
		EN: Text{"Report resolved", "Your report {{ticket}} has been resolved."},
		BN: Text{"অভিযোগের সমাধান", "আপনার অভিযোগ {{ticket}}-এর সমাধান হয়েছে।"}},
}

// Render fills a template in the language ("bn" unless "en").
func Render(template, language string, data map[string]string) (Text, error) {
	t, ok := Templates[template]
	if !ok {
		return Text{}, ErrUnknownTemplate
	}
	text := t.BN
	if language == "en" {
		text = t.EN
	}
	pairs := make([]string, 0, 2*len(data))
	for k, v := range data {
		pairs = append(pairs, "{{"+k+"}}", v)
	}
	r := strings.NewReplacer(pairs...)
	return Text{Title: r.Replace(text.Title), Body: r.Replace(text.Body)}, nil
}
