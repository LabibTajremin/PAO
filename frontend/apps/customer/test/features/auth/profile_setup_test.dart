import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pao_core/pao_core.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/features/auth/data/api_profile_setup_repository.dart';
import 'package:pao_customer/features/auth/domain/profile_setup_repository.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_cubit.dart';
import 'package:pao_customer/features/auth/presentation/profile_setup_page.dart';
import 'package:pao_ui/pao_ui.dart';

import '../../support/harness.dart';

class _Repo implements ProfileSetupRepository {
  final saved = <(String, String, Uint8List?)>[];
  AppFailure? error;

  @override
  Future<void> save({
    required String name,
    required String language,
    Uint8List? photo,
  }) async {
    if (error case final AppFailure e) throw e;
    saved.add((name, language, photo));
  }
}

void main() {
  test('names need 2 to 80 characters', () {
    expect(
      [validName(' a '), validName('Rina'), validName('x' * 81)],
      [false, true, false],
    );
  });

  test('the cubit keeps the photo and reports failures', () async {
    final repo = _Repo();
    final cubit = ProfileSetupCubit(repo)..photo(null);
    expect(cubit.state.photo, isNull);
    cubit.photo(tinyPng);
    await cubit.save('R', 'en');
    expect([cubit.state.invalidName, cubit.state.photo], [true, tinyPng]);
    repo.error = const NetworkFailure();
    await cubit.save('Rina', 'bn');
    expect(cubit.state.failure!.code, 'NETWORK');
    repo.error = null;
    await cubit.save('Rina', 'bn');
    expect(cubit.state.done, isTrue);
    expect(repo.saved.single, ('Rina', 'bn', tinyPng));
  });

  test('the repository uploads the photo before saving', () async {
    final h = await Harness.create();
    final saved = <String>[];
    final repo = ApiProfileSetupRepository(
      h.services.api,
      onSaved: (p) => saved.add(p.name),
      uploader: MediaUploader(
        create: (_) async => const SignedUpload(mediaId: 'm1', url: 'u'),
        confirm: (_) async {},
        storage: _storage(),
      ),
    );
    h.http.onPut('/v1/customer/profile', (s) => s.reply(200, profile()));
    await repo.save(name: 'Nusrat Jahan', language: 'bn', photo: tinyPng);
    expect((h.bodyOf('/v1/customer/profile')! as Map)['photoMediaId'], 'm1');
    expect(saved, ['Nusrat Jahan']);
  });

  testWidgets('a new account sets a name and photo, then picks a location', (
    tester,
  ) async {
    tall(tester);
    final h = await Harness.create();
    await h.signIn(tester, newAccount: true);
    await h.pumpApp(tester);
    expect(find.byType(ProfileSetupPage), findsOneWidget);
    when(() => h.picker.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => XFile.fromData(tinyPng));
    await tester.tap(find.text('Add a photo'));
    await h.settle(tester);
    await tester.tap(find.text('Continue'));
    await h.settle(tester);
    expect(find.text('Enter a name of 2 to 80 characters.'), findsOneWidget);
    h.http.onPost(
      '/v1/customer/uploads',
      (s) => s.reply(422, apiError('UPLOAD_INVALID')),
    );
    await tester.enterText(find.byType(TextField), ' Nusrat Jahan ');
    await tester.tap(find.text('Continue'));
    await h.settle(tester);
    expect(
      find.text('This file cannot be used. Try another photo.'),
      findsOneWidget,
    );
    expect((h.bodyOf('/v1/customer/uploads')! as Map)['purpose'], 'avatar');
    await _saveWithoutPhoto(tester, h);
  });
}

Dio _storage() {
  final dio = Dio();
  DioAdapter(dio: dio)
      .onPut('u', (s) => s.reply(200, null), data: Matchers.any);
  return dio;
}

Future<void> _saveWithoutPhoto(WidgetTester tester, Harness h) async {
  h.services.gate.clear();
  await h.go(tester, Routes.location);
  await h.go(tester, Routes.profileSetup);
  h.http.onPut('/v1/customer/profile', (s) => s.reply(200, profile()));
  await tester.enterText(find.byType(TextField), ' Nusrat Jahan ');
  await tester.tap(find.text('Continue'));
  await h.settle(tester);
  expect(h.bodyOf('/v1/customer/profile'), {
    'name': 'Nusrat Jahan',
    'language': 'en',
  });
  expect(h.services.gate.missing, isFalse);
  expect(find.byType(PlaceholderPage), findsOneWidget);
}
