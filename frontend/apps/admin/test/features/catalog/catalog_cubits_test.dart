import 'package:flutter_test/flutter_test.dart';
import 'package:pao_admin/features/catalog/domain/catalog_repository.dart';
import 'package:pao_admin/features/catalog/presentation/catalog_cubits.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_core/pao_core.dart';

import 'fixtures.dart' as fx;

class _Catalog implements CatalogRepository {
  AppFailure? fail;
  int loads = 0;

  Future<T> _maybeFail<T>(T Function() value) async {
    if (fail != null) throw fail!;
    return value();
  }

  @override
  Future<CatalogTree> tree() async {
    loads++;
    return CatalogTree.fromJson(fx.tree());
  }

  @override
  Future<Category> saveCategory(String? id, CategoryInput input) =>
      _maybeFail(() => Category.fromJson(fx.category()));

  @override
  Future<Service> saveService(String? id, ServiceInput input) =>
      _maybeFail(() => Service.fromJson(fx.service(id: id ?? 'created')));

  @override
  Future<SubService> saveSubService(String? id, SubServiceInput input) =>
      _maybeFail(() => SubService.fromJson(fx.subService()));

  @override
  Future<List<PriceVersion>> prices(String subServiceId) async => [
    PriceVersion.fromJson(fx.priceVersion(100, '2026-01-01T00:00:00Z')),
    PriceVersion.fromJson(fx.priceVersion(300, '2026-03-01T00:00:00Z')),
    PriceVersion.fromJson(fx.priceVersion(200, '2026-02-01T00:00:00Z')),
  ];

  @override
  Future<PriceVersion> changePrice(String subServiceId, int amount) =>
      _maybeFail(
        () =>
            PriceVersion.fromJson(fx.priceVersion(amount, '2026-10-09T00:00Z')),
      );
}

void main() {
  test('a refused category save keeps the tree as it was', () async {
    final repo = _Catalog()..fail = const ApiFailure('CONFLICT', status: 409);
    final cubit = CatalogCubit(repo);
    await cubit.load();
    final failure = await cubit.saveCategory(
      null,
      CategoryInput(
        name: LocalizedText(en: 'a', bn: 'b'),
        iconKey: 'x',
      ),
    );
    expect(failure?.code, 'CONFLICT');
    expect(repo.loads, 1);
  });

  test('the editor finds its service, or reports it missing', () async {
    final repo = _Catalog();
    final found = ServiceEditorCubit(repo, fx.serviceId);
    await found.load();
    expect(
      (found.state as ViewData<ServiceEditorData>).data.service?.id,
      fx.serviceId,
    );
    expect(found.repository, same(repo));
    final missing = ServiceEditorCubit(repo, 'nope');
    await missing.load();
    expect((missing.state as ViewFailure).failure.code, 'NOT_FOUND');
    final fresh = ServiceEditorCubit(repo, null);
    await fresh.load();
    expect((fresh.state as ViewData<ServiceEditorData>).data.service, isNull);
  });

  test('creating a service returns it without reloading', () async {
    final repo = _Catalog();
    final cubit = ServiceEditorCubit(repo, null);
    await cubit.load();
    final input = ServiceInput.fromJson({
      ...fx.service(),
      'categoryId': fx.categoryId,
    });
    final (saved, failure) = await cubit.saveService(null, input);
    expect((saved?.id, failure), ('created', null));
    expect(repo.loads, 1);
    repo.fail = const NetworkFailure();
    final (none, refused) = await cubit.saveService(fx.serviceId, input);
    expect((none, refused?.code), (null, 'NETWORK'));
  });

  test('prices come newest first; a refused change is reported', () async {
    final repo = _Catalog();
    final cubit = PriceCubit(repo, fx.subId);
    await cubit.load();
    final amounts = (cubit.state as ViewData<List<PriceVersion>>).data.map(
      (v) => v.amount,
    );
    expect(amounts, [300, 200, 100]);
    repo.fail = const NetworkFailure();
    expect((await cubit.change(500))?.code, 'NETWORK');
  });

  test('taka amounts turn into paisa', () {
    expect(parsePaisa('500'), 50000);
    expect(parsePaisa(' 499.5 '), 49950);
    expect(parsePaisa('499.05'), 49905);
    expect(parsePaisa('1.234'), isNull);
    expect(parsePaisa('-1'), isNull);
  });
}
