import 'package:flutter/widgets.dart';
import 'package:pao_admin/features/catalog/presentation/localized_fields.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_api/pao_api.dart';

/// The sub-service form's values while the admin edits them (A04).
class SubServiceDraft {
  /// Starts from [sub], or from defaults for a new one under [serviceId].
  SubServiceDraft(this.serviceId, SubService? sub)
    : isNew = sub == null,
      name = LocalizedInput(sub?.name),
      description = LocalizedInput(sub?.description),
      inclusions = [
        for (final i in sub?.inclusions ?? _none) LocalizedInput(i),
      ],
      exclusions = [
        for (final e in sub?.exclusions ?? _none) LocalizedInput(e),
      ],
      unit = sub?.unit ?? PriceUnit.job,
      maxQuantity = TextEditingController(
        text: sub?.maxQuantity == null ? '' : '${sub!.maxQuantity}',
      ),
      published = sub?.published ?? false;

  static const _none = <LocalizedText>[];

  /// Service the sub-service belongs to.
  final String serviceId;

  /// Creating rather than editing; only then is a first price asked.
  final bool isNew;

  /// Name in both languages.
  final LocalizedInput name;

  /// Optional description in both languages.
  final LocalizedInput description;

  /// What the price includes.
  final List<LocalizedInput> inclusions;

  /// What the price leaves out.
  final List<LocalizedInput> exclusions;

  /// What one quantity means.
  PriceUnit unit;

  /// Most a customer may book at once; empty for no limit.
  final TextEditingController maxQuantity;

  /// First price in taka, for a new sub-service.
  final price = TextEditingController();

  /// Customers can see the sub-service.
  bool published;

  /// Field errors from the last [check].
  final errors = FormErrors();

  /// Checks every field like the API does; true when the draft can be sent.
  bool check(AdminL10n t) {
    errors.clear();
    name.check(t, errors);
    description.check(t, errors, optional: true);
    for (final item in [...inclusions, ...exclusions]) {
      item.check(t, errors);
    }
    errors
      ..set(
        maxQuantity,
        maxQuantity.text.trim().isEmpty
            ? null
            : checkWhole(t, maxQuantity.text, min: 1),
      )
      ..set(price, isNew ? checkMoney(t, price.text) : null);
    return errors.isEmpty;
  }

  /// The draft as the API takes it; call after [check] passed.
  SubServiceInput toInput() => SubServiceInput(
    serviceId: serviceId,
    name: name.value,
    description: description.isBlank ? null : description.value,
    inclusions: [for (final i in inclusions) i.value],
    exclusions: [for (final e in exclusions) e.value],
    unit: unit,
    maxQuantity: int.tryParse(maxQuantity.text.trim()),
    initialPrice: isNew ? parsePaisa(price.text) : null,
    published: published,
  );

  /// Releases the controllers.
  void dispose() {
    for (final input in [name, description, ...inclusions, ...exclusions]) {
      input.dispose();
    }
    maxQuantity.dispose();
    price.dispose();
  }
}
