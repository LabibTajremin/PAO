import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/auth/domain/admin_auth_repository.dart';
import 'package:pao_admin/features/auth/presentation/login_cubit.dart';
import 'package:pao_admin/features/auth/presentation/password_cubit.dart';
import 'package:pao_core/pao_core.dart';

class _Repo implements AdminAuthRepository {
  AppFailure? error;

  @override
  Future<LoginChallenge> login(String email, String password) async =>
      const LoginChallenge(id: 'c1', mustChangePassword: true);

  @override
  Future<String> verify(String challengeId, String code) async => 'token';

  @override
  Future<void> changePassword(String current, String next) async {
    if (error case final AppFailure e) throw e;
  }
}

void main() {
  test('a closed cubit ignores a late sign-in', () async {
    final signedIn = <(String, bool)>[];
    final cubit = LoginCubit(
      _Repo(),
      onSignedIn: (token, {required mustChange}) async {
        signedIn.add((token, mustChange));
      },
    );
    await cubit.login('a@pao.bd', 'secret-pass');
    final pending = cubit.verify('123456');
    await cubit.close();
    await pending;
    expect(signedIn, [('token', true)]);
  });

  test('password changes are checked before sending', () async {
    final repo = _Repo();
    final cubit = PasswordCubit(repo);
    await cubit.change('old', 'short', 'short');
    expect(cubit.state.problem, PasswordProblem.tooShort);
    await cubit.change('old', 'long-enough-pass', 'other-long-pass');
    expect(cubit.state.problem, PasswordProblem.mismatch);
    repo.error = const NetworkFailure();
    await cubit.change('old', 'long-enough-pass', 'long-enough-pass');
    expect(cubit.state.failure!.code, 'NETWORK');
    repo.error = null;
    await cubit.change('old', 'long-enough-pass', 'long-enough-pass');
    expect(cubit.state.done, isTrue);
  });
}
