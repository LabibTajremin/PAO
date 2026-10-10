import 'dart:async';

import 'package:pao_core/pao_core.dart';
import 'package:pao_partner/features/jobs/presentation/paged_cubit.dart';

/// Starts the first load as a [LoadCubit] is created in `BlocProvider.create`.
extension LoadOnCreate<C extends LoadCubit<Object?>> on C {
  /// Starts [LoadCubit.load] and returns the cubit.
  C loading() {
    unawaited(load());
    return this;
  }
}

/// Starts the first page as a [PagedCubit] is created in `BlocProvider.create`.
extension PageOnCreate<C extends PagedCubit<Object?>> on C {
  /// Starts [PagedCubit.load] and returns the cubit.
  C loading() {
    unawaited(load());
    return this;
  }
}
