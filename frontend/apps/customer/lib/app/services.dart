import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/gate.dart';
import 'package:pao_customer/features/location/domain/places.dart';
import 'package:pao_l10n/pao_l10n.dart';

/// Long-lived services shared by every screen of the customer app. Feature
/// repositories are built from [api].
class AppServices {
  /// Bundles the services.
  AppServices({
    required this.sessions,
    required this.permissions,
    required this.locale,
    required this.api,
    required this.prefs,
    required this.online,
    required this.location,
    required this.launcher,
    required this.photos,
    required this.push,
    this.places = const NoPlacesService(),
    DateTime Function()? clock,
  }) : now = clock ?? DateTime.now,
       gate = ProfileGate(api);

  /// The signed-in session.
  final SessionManager sessions;

  /// What the account may see and do.
  final PermissionService permissions;

  /// The language the app shows.
  final LocaleController locale;

  /// Authenticated client for the PAO API.
  final Dio api;

  /// Settings that survive restarts.
  final Prefs prefs;

  /// Whether the device has a network (C36).
  final ValueNotifier<bool> online;

  /// Device position, for detecting the address (C06).
  final LocationService location;

  /// Dialler and share hand-off.
  final Launcher launcher;

  /// Camera and gallery.
  final PhotoSource photos;

  /// Push notifications.
  final PushService push;

  /// Address search on the maps provider (C06).
  final PlacesService places;

  /// Current time; injectable so countdowns are testable.
  final DateTime Function() now;

  /// Whether the signed-in customer still has to set up a profile.
  final ProfileGate gate;
}
