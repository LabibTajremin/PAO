import 'package:flutter/painting.dart';

/// The picture behind a signed photo URL from the API, or null without one.
ImageProvider? networkPhoto(String? url) =>
    url == null ? null : NetworkImage(url);
