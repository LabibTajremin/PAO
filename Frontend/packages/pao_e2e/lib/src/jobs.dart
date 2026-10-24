import 'package:pao_e2e/src/client.dart';

/// A provider working a booking over plain HTTP, while a journey drives the
/// customer app.
class JobDriver {
  /// Creates the driver acting as [provider].
  const JobDriver(this._stack, this.provider);

  final StackClient _stack;

  /// The provider's session.
  final ApiSession provider;

  /// The ID of the provider's newest incoming request, once it arrives.
  Future<String> nextRequest() async {
    String? id;
    await eventually('a booking request', () async {
      final list = await _stack.send(
        'GET',
        '/v1/provider/jobs?tab=requests',
        as: provider,
      );
      final items = list['items']! as List<Object?>;
      if (items.firstOrNull case {'id': final String first}) id = first;
      return id != null;
    });
    return id!;
  }

  /// Moves the job on: `accept`, `on-the-way` or `arrived`.
  Future<void> mark(String id, String step) =>
      _stack.send('POST', '/v1/provider/jobs/$id/$step', as: provider);

  /// Starts the job with the customer's start [code].
  Future<void> start(String id, String code) => _stack.send(
    'POST',
    '/v1/provider/jobs/$id/start',
    body: {'code': code},
    as: provider,
  );

  /// Completes the job, confirming the cash was received.
  Future<void> complete(String id) => _stack.send(
    'POST',
    '/v1/provider/jobs/$id/complete',
    body: {'cashReceived': true},
    as: provider,
  );
}
