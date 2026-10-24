import 'package:dio/dio.dart';
import 'package:pao_e2e/pao_e2e.dart';

/// The due block limit, an admin setting in paisa (ADR-0035 §3).
const dueBlockKey = 'billing.due_block_amount';

/// A customer booking the merchant over HTTP, as test/e2e/api does, so only
/// the partner app is driven.
class CustomerBooker {
  CustomerBooker._(this._stack, this._session, this._address);

  /// Signs a new customer up at [phone] with a default address in Banani.
  static Future<CustomerBooker> create(StackClient stack, String phone) async {
    final c = await PartnerDriver(stack).signIn(phone, app: 'customer');
    await stack.send(
      'PUT',
      '/v1/customer/profile',
      body: {'name': 'Nusrat Jahan', 'language': 'en'},
      as: c,
    );
    final address = await stack.send(
      'POST',
      '/v1/customer/addresses',
      body: {
        'label': 'home',
        'line1': 'House 12, Road 5, Banani',
        'location': banani,
        'isDefault': true,
      },
      as: c,
    );
    return CustomerBooker._(stack, c, '${address['id']}');
  }

  final StackClient _stack;
  final ApiSession _session;
  final String _address;

  /// Books the first Electrician sub-service ASAP with [providerId]; returns
  /// the booking ID.
  Future<String> book(String providerId) async {
    final (service, sub) = await _electrician();
    final res = await _stack.http.post<Object?>(
      '/v1/customer/bookings',
      data: {
        'providerId': providerId,
        'serviceId': service,
        'timing': 'asap',
        'addressId': _address,
        'items': [
          {'subServiceId': sub, 'quantity': 1},
        ],
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_session.token}',
          'Idempotency-Key': 'e2e-${DateTime.now().microsecondsSinceEpoch}',
        },
      ),
    );
    if (res.statusCode != 201) throw StackError('book: ${res.data}');
    return '${(res.data! as Json)['id']}';
  }

  /// The code the customer reads out on arrival.
  Future<String> startCode(String id) async {
    final path = '/v1/customer/bookings/$id/start-code';
    final reply = await _stack.send('GET', path, as: _session);
    return '${reply['code']}';
  }

  Future<(String, String)> _electrician() async {
    final tree = await _stack.send('GET', '/v1/customer/catalog', as: _session);
    for (final category in tree['categories']! as List<Object?>) {
      for (final service in (category! as Json)['services']! as List<Object?>) {
        if (service case {
          'id': final String id,
          'name': {'en': 'Electrician'},
          'subServices': [{'id': final String sub}, ...],
        }) {
          return (id, sub);
        }
      }
    }
    throw const StackError('no Electrician service');
  }
}

/// The super admin's side of billing: the block limit and payment review.
class BillingAdmin {
  /// Creates the driver.
  const BillingAdmin(this._stack, this._admins);

  final StackClient _stack;
  final AdminDriver _admins;

  Future<ApiSession> get _root => _admins.signIn('super@pao.bd');

  /// Sets the due block limit to [paisa]; returns the value it had.
  Future<String> setDueLimit(String paisa) async {
    final root = await _root;
    final list = await _stack.send('GET', '/v1/admin/settings', as: root);
    final before = [
      for (final s in list['items']! as List<Object?>)
        if (s case {'key': dueBlockKey, 'value': final String v}) v,
    ].firstOrNull;
    await _stack.send(
      'PUT',
      '/v1/admin/settings/$dueBlockKey',
      body: {'value': paisa},
      as: root,
    );
    return before ?? '50000';
  }

  /// Confirms the pending payment [providerId] reported, once it arrives.
  Future<void> confirmPayment(String providerId) async {
    final root = await _root;
    String? id;
    await eventually('a pending payment of $providerId', () async {
      final page = await _stack.send(
        'GET',
        '/v1/admin/billing/payments?status=pending',
        as: root,
      );
      for (final p in page['items']! as List<Object?>) {
        if (p case {'id': final String found, 'providerId': final String who}
            when who == providerId) {
          id = found;
        }
      }
      return id != null;
    });
    await _stack.send(
      'POST',
      '/v1/admin/billing/payments/$id/confirm',
      as: root,
    );
  }
}
