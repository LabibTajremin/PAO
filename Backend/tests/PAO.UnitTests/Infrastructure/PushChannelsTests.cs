using System.Text.Json;
using PAO.Core.Areas.Notification.Services;
using PAO.Infrastructure.Push;

namespace PAO.UnitTests.Infrastructure;

public sealed class PushChannelsTests
{
    [Theory]
    [InlineData("booking_requested", PushChannels.Bookings, "time-sensitive")]
    [InlineData("booking_cancelled", PushChannels.Bookings, "time-sensitive")]
    [InlineData("payment_confirmed", PushChannels.Account, "active")]
    [InlineData("document_expiring", PushChannels.Account, "active")]
    [InlineData("admin_broadcast", PushChannels.General, "active")]
    [InlineData(null, PushChannels.General, "active")]
    public void Types_map_to_channels_and_interruption_levels(string? type, string channel, string level)
    {
        Assert.Equal(channel, PushChannels.For(type));
        Assert.Equal(level, PushChannels.InterruptionLevel(channel));
    }

    // A new template without a channel would silently fall back to "general"; this keeps the
    // mapping complete.
    [Fact]
    public void Every_template_has_its_own_channel()
    {
        var unmapped = NotificationTemplates.All.Keys.Where(t => PushChannels.For(t) == PushChannels.General);
        Assert.Empty(unmapped);
    }

    [Fact]
    public void Payload_asks_for_a_heads_up_banner_on_both_platforms()
    {
        var data = new Dictionary<string, string> { ["type"] = "booking_requested", ["bookingId"] = "b1" };
        var json = JsonSerializer.SerializeToElement(FcmPushSender.Payload("device", new PushMessage("Title", "Body", data)));
        var message = json.GetProperty("message");
        Assert.Equal("device", message.GetProperty("token").GetString());
        Assert.Equal("Title", message.GetProperty("notification").GetProperty("title").GetString());
        Assert.Equal("b1", message.GetProperty("data").GetProperty("bookingId").GetString());
        var android = message.GetProperty("android");
        Assert.Equal("high", android.GetProperty("priority").GetString());
        var notification = android.GetProperty("notification");
        Assert.Equal(PushChannels.Bookings, notification.GetProperty("channel_id").GetString());
        Assert.Equal("PRIORITY_HIGH", notification.GetProperty("notification_priority").GetString());
        Assert.True(notification.GetProperty("default_sound").GetBoolean());
        var apns = message.GetProperty("apns");
        Assert.Equal("10", apns.GetProperty("headers").GetProperty("apns-priority").GetString());
        Assert.Equal("alert", apns.GetProperty("headers").GetProperty("apns-push-type").GetString());
        var aps = apns.GetProperty("payload").GetProperty("aps");
        Assert.Equal("default", aps.GetProperty("sound").GetString());
        Assert.Equal("time-sensitive", aps.GetProperty("interruption-level").GetString());
    }
}
