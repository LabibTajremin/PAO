import 'package:url_launcher/url_launcher.dart';

/// Opens other apps: maps for directions (P-07), the dialler and email.
class Launcher {
  /// Creates the launcher; [open] is injectable for tests.
  Launcher({Future<bool> Function(Uri uri)? open}) : _open = open ?? _external;

  final Future<bool> Function(Uri uri) _open;

  static Future<bool> _external(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  /// Opens Google Maps directions to the point.
  Future<bool> directions(double lat, double lng) => _open(
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
    }),
  );

  /// Opens the dialler with [phone].
  Future<bool> call(String phone) => _open(Uri(scheme: 'tel', path: phone));

  /// Opens the mail app with a message to [address] about [subject].
  Future<bool> email(String address, {String? subject}) => _open(
    Uri(
      scheme: 'mailto',
      path: address,
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    ),
  );
}
