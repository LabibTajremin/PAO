import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pao_core/pao_core.dart';

/// Keeps the chosen language on the phone and on the profile, so
/// notifications and SMS from PAO use it too (C26, C-15). The state is why
/// the profile update failed, if it did; the choice is still kept on the
/// phone.
class LanguageCubit extends Cubit<AppFailure?> {
  /// Creates the cubit; [keep] stores the code locally, [upload] on the
  /// profile.
  LanguageCubit({required this.keep, required this.upload}) : super(null);

  /// Stores the code on the phone.
  final Future<void> Function(String code) keep;

  /// Stores the code on the profile.
  final Future<void> Function(String code) upload;

  /// Saves [code] in both places.
  Future<void> select(String code) async {
    await keep(code);
    final failure = await attempt(() => upload(code));
    if (!isClosed) emit(failure);
  }
}
