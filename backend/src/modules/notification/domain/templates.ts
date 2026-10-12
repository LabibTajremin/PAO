/** A title and body pair. */
export interface Message {
  readonly title: string;
  readonly body: string;
}

/** A message in both languages; `{{name}}` marks a value from the data. */
export interface Template {
  readonly en: Message;
  readonly bn: Message;
}

const t = (en: [string, string], bn: [string, string]): Template => ({
  en: { title: en[0], body: en[1] },
  bn: { title: bn[0], body: bn[1] },
});

/** Every event that notifies someone (02-architecture.md §8). */
export const TEMPLATES: Readonly<Record<string, Template>> = {
  booking_requested: t(
    ['New booking request', '{{service}} in {{area}} — answer before the time runs out.'],
    ['নতুন বুকিং অনুরোধ', '{{area}}-এ {{service}} — সময় শেষ হওয়ার আগে উত্তর দিন।'],
  ),
  booking_accepted: t(
    ['Booking accepted', '{{provider}} accepted booking {{number}}.'],
    ['বুকিং গৃহীত', '{{provider}} বুকিং {{number}} গ্রহণ করেছেন।'],
  ),
  booking_rejected: t(
    [
      'Provider unavailable',
      '{{provider}} cannot take booking {{number}}. Please choose another provider.',
    ],
    [
      'সেবাদাতা ব্যস্ত',
      '{{provider}} বুকিং {{number}} নিতে পারছেন না। অনুগ্রহ করে অন্য সেবাদাতা বেছে নিন।',
    ],
  ),
  booking_timed_out: t(
    [
      'No answer yet',
      'Booking {{number}} was not answered in time. Please choose another provider.',
    ],
    [
      'উত্তর পাওয়া যায়নি',
      'বুকিং {{number}}-এর সময়মতো উত্তর আসেনি। অনুগ্রহ করে অন্য সেবাদাতা বেছে নিন।',
    ],
  ),
  request_missed: t(
    ['Request expired', 'You did not answer booking {{number}} in time.'],
    ['অনুরোধের সময় শেষ', 'আপনি সময়মতো বুকিং {{number}}-এর উত্তর দেননি।'],
  ),
  provider_on_the_way: t(
    ['Provider on the way', '{{provider}} is on the way.'],
    ['সেবাদাতা আসছেন', '{{provider}} রওনা হয়েছেন।'],
  ),
  provider_arrived: t(
    ['Provider arrived', '{{provider}} has arrived. Share your start code to begin.'],
    ['সেবাদাতা পৌঁছেছেন', '{{provider}} পৌঁছেছেন। কাজ শুরু করতে আপনার স্টার্ট কোড দিন।'],
  ),
  booking_started: t(
    ['Job started', 'Booking {{number}} is in progress.'],
    ['কাজ শুরু হয়েছে', 'বুকিং {{number}}-এর কাজ চলছে।'],
  ),
  extras_proposed: t(
    [
      'Extra items to approve',
      'Your provider added items worth ৳{{added}}. Please approve or decline.',
    ],
    [
      'অতিরিক্ত আইটেম অনুমোদন',
      'আপনার সেবাদাতা ৳{{added}} মূল্যের আইটেম যোগ করেছেন। অনুমোদন বা বাতিল করুন।',
    ],
  ),
  extras_decided: t(
    ['Customer answered', 'The customer {{decision}} the extra items on booking {{number}}.'],
    ['গ্রাহকের উত্তর', 'গ্রাহক বুকিং {{number}}-এর অতিরিক্ত আইটেম {{decision}}।'],
  ),
  booking_completed: t(
    ['Job complete', 'Booking {{number}} is complete. Please rate your experience.'],
    ['কাজ সম্পন্ন', 'বুকিং {{number}} সম্পন্ন হয়েছে। আপনার অভিজ্ঞতা মূল্যায়ন করুন।'],
  ),
  booking_cancelled: t(
    ['Booking cancelled', 'Booking {{number}} was cancelled.'],
    ['বুকিং বাতিল', 'বুকিং {{number}} বাতিল করা হয়েছে।'],
  ),
  level_changed: t(
    ['Verification updated', 'Your verification level is now {{level}}.'],
    ['যাচাই হালনাগাদ', 'আপনার যাচাই স্তর এখন {{level}}।'],
  ),
  document_rejected: t(
    ['Document needs attention', 'Your {{item}} was not approved: {{reason}}'],
    ['নথি ঠিক করুন', 'আপনার {{item}} অনুমোদিত হয়নি: {{reason}}'],
  ),
  document_expired: t(
    ['Document expired', 'Your {{item}} has expired. Renew it to receive bookings again.'],
    ['নথির মেয়াদ শেষ', 'আপনার {{item}}-এর মেয়াদ শেষ। আবার বুকিং পেতে নবায়ন করুন।'],
  ),
  document_expiring: t(
    ['Document expiring soon', 'Your {{item}} expires in {{days}} days.'],
    ['নথির মেয়াদ শেষ হতে চলেছে', 'আপনার {{item}}-এর মেয়াদ {{days}} দিনের মধ্যে শেষ হবে।'],
  ),
  level2_scheduled: t(
    ['Skill check scheduled', 'Your Level 2 session is at {{location}} on {{when}}.'],
    ['দক্ষতা যাচাই নির্ধারিত', 'আপনার লেভেল ২ সেশন {{when}} তারিখে {{location}}-এ।'],
  ),
  complaint_resolved: t(
    ['Report resolved', 'Your report {{ticket}} has been resolved.'],
    ['অভিযোগের সমাধান', 'আপনার অভিযোগ {{ticket}}-এর সমাধান হয়েছে।'],
  ),
};

function fill(text: string, data: Readonly<Record<string, string>>): string {
  return text.replace(/\{\{(\w+)\}\}/g, (tag, key: string) => data[key] ?? tag);
}

/** Fills a template in the language (Bangla unless "en"); undefined for an unknown one. */
export function render(
  template: string,
  language: string,
  data: Readonly<Record<string, string>>,
): Message | undefined {
  const found = Object.hasOwn(TEMPLATES, template) ? TEMPLATES[template] : undefined;
  if (found === undefined) {
    return undefined;
  }
  const text = language === 'en' ? found.en : found.bn;
  return { title: fill(text.title, data), body: fill(text.body, data) };
}
