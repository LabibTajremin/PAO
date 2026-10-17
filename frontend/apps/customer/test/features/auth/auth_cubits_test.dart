import 'package:flutter_test/flutter_test.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/features/auth/domain/auth_repository.dart';
import 'package:pao_customer/features/auth/presentation/otp_cubit.dart';
import 'package:pao_customer/features/auth/presentation/phone_cubit.dart';

class _Repo implements AuthRepository {
  AppFailure? fail;
  final requested = <String>[];

  @override
  Future<CodeSent> requestCode(String phone) async {
    if (fail != null) throw fail!;
    requested.add(phone);
    return const CodeSent(resendAfter: Duration(seconds: 45));
  }

  @override
  Future<SignedIn> verify(String phone, String code) async {
    if (code != '123456') throw const ApiFailure('OTP_INVALID', status: 422);
    return const SignedIn(accessToken: 'a', refreshToken: 'r');
  }
}

void main() {
  test('phone numbers are normalised to 01XXXXXXXXX', () {
    for (final input in [
      '01712345678',
      '1712345678',
      '+880 1712-345678',
      '8801712345678',
    ]) {
      expect(normalisePhone(input), '01712345678', reason: input);
    }
    for (final input in ['', '0171234567', '01212345678', '021234567890']) {
      expect(normalisePhone(input), isNull, reason: input);
    }
  });

  test('phone cubit validates, sends and reports failures', () async {
    final repo = _Repo();
    final cubit = PhoneCubit(repo);
    await cubit.submit('123');
    expect(cubit.state.invalid, isTrue);
    await cubit.submit('1712345678');
    expect(cubit.state.sentTo, '01712345678');
    repo.fail = const NetworkFailure();
    await cubit.submit('01712345678');
    expect([cubit.state.sentTo, cubit.state.failure!.code], [null, 'NETWORK']);
  });

  testWidgets('otp cubit counts down, resends and signs in', (tester) async {
    final repo = _Repo();
    SignedIn? stored;
    final cubit = OtpCubit(
      repo,
      '01712345678',
      resendAfter: 2,
      onSignedIn: (t) async => stored = t,
    );
    await cubit.resend();
    expect(repo.requested, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(cubit.state.resendIn, 0);
    await cubit.resend();
    expect([repo.requested.length, cubit.state.resendIn], [1, 45]);
    await cubit.verify('000000');
    expect([cubit.state.wrongCode, cubit.state.done], [true, false]);
    await cubit.verify('123456');
    expect([cubit.state.done, stored!.refreshToken], [true, 'r']);
    await cubit.close();
  });

  testWidgets('otp cubit reports resend failures', (tester) async {
    final repo = _Repo()..fail = const ApiFailure('RATE_LIMITED', status: 429);
    final cubit = OtpCubit(
      repo,
      '01712345678',
      resendAfter: 0,
      onSignedIn: (_) async {},
    );
    await cubit.resend();
    expect(
      [cubit.state.failure!.code, cubit.state.wrongCode],
      ['RATE_LIMITED', false],
    );
    expect(
      const OtpState(
        resendIn: 1,
        failure: ApiFailure('OTP_EXPIRED', status: 422),
      ).wrongCode,
      isTrue,
    );
    await cubit.close();
  });
}
