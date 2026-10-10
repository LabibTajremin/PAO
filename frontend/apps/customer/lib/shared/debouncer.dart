import 'dart:async';

/// Runs only the last action of a burst, e.g. one search per pause in typing.
class Debouncer {
  /// Creates the debouncer; [delay] is the pause that ends a burst.
  Debouncer([this.delay = const Duration(milliseconds: 300)]);

  /// The pause that ends a burst.
  final Duration delay;

  Timer? _timer;

  /// Runs [action] once no other call follows within [delay].
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Drops the pending action.
  void cancel() => _timer?.cancel();
}
