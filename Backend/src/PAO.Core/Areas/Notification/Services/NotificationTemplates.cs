using System.Text.RegularExpressions;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>A title and body pair.</summary>
public sealed record RenderedText(string Title, string Body);

/// <summary>Every message in English and Bangla (02-architecture §8); `{{name}}` marks a value from the data.</summary>
public static partial class NotificationTemplates
{
    /// <summary>The templates by name: (English, Bangla).</summary>
    public static readonly IReadOnlyDictionary<string, (RenderedText En, RenderedText Bn)> All = new Dictionary<string, (RenderedText, RenderedText)>(StringComparer.Ordinal)
    {
        ["booking_requested"] = (new("New booking request", "{{service}} in {{area}} — answer before the time runs out."), new("নতুন বুকিং অনুরোধ", "{{area}}-এ {{service}} — সময় শেষ হওয়ার আগে উত্তর দিন।")),
        ["booking_accepted"] = (new("Booking accepted", "{{provider}} accepted booking {{number}}."), new("বুকিং গৃহীত", "{{provider}} বুকিং {{number}} গ্রহণ করেছেন।")),
        ["booking_rejected"] = (new("Provider unavailable", "{{provider}} cannot take booking {{number}}. Please choose another provider."), new("সেবাদাতা ব্যস্ত", "{{provider}} বুকিং {{number}} নিতে পারছেন না। অনুগ্রহ করে অন্য সেবাদাতা বেছে নিন।")),
        ["booking_timed_out"] = (new("No answer yet", "Booking {{number}} was not answered in time. Please choose another provider."), new("উত্তর পাওয়া যায়নি", "বুকিং {{number}}-এর সময়মতো উত্তর আসেনি। অনুগ্রহ করে অন্য সেবাদাতা বেছে নিন।")),
        ["request_missed"] = (new("Request expired", "You did not answer booking {{number}} in time."), new("অনুরোধের সময় শেষ", "আপনি সময়মতো বুকিং {{number}}-এর উত্তর দেননি।")),
        ["provider_on_the_way"] = (new("Provider on the way", "{{provider}} is on the way."), new("সেবাদাতা আসছেন", "{{provider}} রওনা হয়েছেন।")),
        ["provider_arrived"] = (new("Provider arrived", "{{provider}} has arrived. Share your start code to begin."), new("সেবাদাতা পৌঁছেছেন", "{{provider}} পৌঁছেছেন। কাজ শুরু করতে আপনার স্টার্ট কোড দিন।")),
        ["booking_started"] = (new("Job started", "Booking {{number}} is in progress."), new("কাজ শুরু হয়েছে", "বুকিং {{number}}-এর কাজ চলছে।")),
        ["extras_proposed"] = (new("Extra items to approve", "Your provider added items worth ৳{{added}}. Please approve or decline."), new("অতিরিক্ত আইটেম অনুমোদন", "আপনার সেবাদাতা ৳{{added}} মূল্যের আইটেম যোগ করেছেন। অনুমোদন বা বাতিল করুন।")),
        ["extras_decided"] = (new("Customer answered", "The customer {{decision}} the extra items on booking {{number}}."), new("গ্রাহকের উত্তর", "গ্রাহক বুকিং {{number}}-এর অতিরিক্ত আইটেম {{decision}}।")),
        ["booking_completed"] = (new("Job complete", "Booking {{number}} is complete. Please rate your experience."), new("কাজ সম্পন্ন", "বুকিং {{number}} সম্পন্ন হয়েছে। আপনার অভিজ্ঞতা মূল্যায়ন করুন।")),
        ["booking_cancelled"] = (new("Booking cancelled", "Booking {{number}} was cancelled."), new("বুকিং বাতিল", "বুকিং {{number}} বাতিল করা হয়েছে।")),
        ["level_changed"] = (new("Verification updated", "Your verification level is now {{level}}."), new("যাচাই হালনাগাদ", "আপনার যাচাই স্তর এখন {{level}}।")),
        ["document_rejected"] = (new("Document needs attention", "Your {{item}} was not approved: {{reason}}"), new("নথি ঠিক করুন", "আপনার {{item}} অনুমোদিত হয়নি: {{reason}}")),
        ["document_expired"] = (new("Document expired", "Your {{item}} has expired. Renew it to receive bookings again."), new("নথির মেয়াদ শেষ", "আপনার {{item}}-এর মেয়াদ শেষ। আবার বুকিং পেতে নবায়ন করুন।")),
        ["document_expiring"] = (new("Document expiring soon", "Your {{item}} expires in {{days}} days."), new("নথির মেয়াদ শেষ হতে চলেছে", "আপনার {{item}}-এর মেয়াদ {{days}} দিনের মধ্যে শেষ হবে।")),
        ["level2_scheduled"] = (new("Skill check scheduled", "Your Level 2 session is at {{location}} on {{when}}."), new("দক্ষতা যাচাই নির্ধারিত", "আপনার লেভেল ২ সেশন {{when}} তারিখে {{location}}-এ।")),
        ["commission_charged"] = (new("Commission added", "PAO commission of ৳{{amount}} was added. Your due is ৳{{due}}."), new("কমিশন যোগ হয়েছে", "৳{{amount}} পাও কমিশন যোগ হয়েছে। আপনার বকেয়া ৳{{due}}।")),
        ["due_limit_reached"] = (new("Pay your due to take jobs", "Your due is ৳{{due}}, above the limit. Pay it from Billing to accept new jobs."), new("কাজ নিতে বকেয়া পরিশোধ করুন", "আপনার বকেয়া ৳{{due}}, সীমার বেশি। নতুন কাজ নিতে বিলিং থেকে পরিশোধ করুন।")),
        ["payment_submitted"] = (new("Payment received for review", "We received your payment of ৳{{amount}} and will check it soon."), new("পেমেন্ট যাচাইয়ের জন্য গৃহীত", "আপনার ৳{{amount}} পেমেন্ট পেয়েছি, শীঘ্রই যাচাই করা হবে।")),
        ["payment_confirmed"] = (new("Payment confirmed", "Your payment of ৳{{amount}} was confirmed. Your due is ৳{{due}}."), new("পেমেন্ট নিশ্চিত", "আপনার ৳{{amount}} পেমেন্ট নিশ্চিত হয়েছে। আপনার বকেয়া ৳{{due}}।")),
        ["payment_rejected"] = (new("Payment not accepted", "Your payment of ৳{{amount}} was not accepted: {{reason}}"), new("পেমেন্ট গৃহীত হয়নি", "আপনার ৳{{amount}} পেমেন্ট গৃহীত হয়নি: {{reason}}")),
        ["complaint_resolved"] = (new("Report resolved", "Your report {{ticket}} has been resolved."), new("অভিযোগের সমাধান", "আপনার অভিযোগ {{ticket}}-এর সমাধান হয়েছে।")),
    };

    /// <summary>Fills a template in the language (Bangla unless "en"); null for an unknown one. Unknown placeholders stay.</summary>
    public static RenderedText? Render(string template, string language, IReadOnlyDictionary<string, string> data)
    {
        if (!All.TryGetValue(template, out var found))
        {
            return null;
        }
        var text = language == "en" ? found.En : found.Bn;
        return new RenderedText(Fill(text.Title, data), Fill(text.Body, data));
    }

    private static string Fill(string text, IReadOnlyDictionary<string, string> data) =>
        Placeholder().Replace(text, m => data.TryGetValue(m.Groups[1].Value, out var value) ? value : m.Value);

    [GeneratedRegex(@"\{\{(\w+)\}\}")]
    private static partial Regex Placeholder();
}
