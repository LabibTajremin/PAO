import 'package:flutter/widgets.dart';
import 'package:pao_admin/features/catalog/presentation/localized_fields.dart';
import 'package:pao_admin/l10n/generated/admin_localizations.dart';
import 'package:pao_admin/shared/form_checks.dart';
import 'package:pao_api/pao_api.dart';

/// The service form's values while the admin edits them (A04).
class ServiceDraft {
  /// Starts from [service], or from defaults filed under [categoryId].
  ServiceDraft(Service? service, {String? categoryId})
    : categoryId = service?.categoryId ?? categoryId,
      name = LocalizedInput(service?.name),
      icon = TextEditingController(text: service?.iconKey),
      radius = TextEditingController(
        text: '${service?.searchRadiusM ?? defaultRadiusM}',
      ),
      model = service?.serviceModel ?? ServiceModel.onDemand,
      level = service?.requiredLevel ?? 1,
      womenOnly = service?.womenProvidersOnly ?? false,
      requiresLevel2 = service?.requiresLevel2 ?? false,
      checklist = [
        for (final item in service?.level2Checklist ?? const <LocalizedText>[])
          LocalizedInput(item),
      ],
      published = service?.published ?? false;

  /// Search radius of a new service, in metres.
  static const defaultRadiusM = 5000;

  /// Smallest search radius the API accepts, in metres.
  static const minRadiusM = 500;

  /// Largest search radius the API accepts, in metres.
  static const maxRadiusM = 50000;

  /// Category the service is filed under.
  String? categoryId;

  /// Name in both languages.
  final LocalizedInput name;

  /// Icon key.
  final TextEditingController icon;

  /// How far to look for providers, in metres.
  final TextEditingController radius;

  /// How the service is sold.
  ServiceModel model;

  /// Verification level a provider needs.
  int level;

  /// Only women providers receive these requests.
  bool womenOnly;

  /// Providers must pass a Level 2 skill check.
  bool requiresLevel2;

  /// What the Level 2 check covers.
  final List<LocalizedInput> checklist;

  /// Customers can see the service.
  bool published;

  /// Field errors from the last [check].
  final errors = FormErrors();

  /// Set when no category is chosen.
  String? categoryError;

  /// Checks every field like the API does; true when the draft can be sent.
  bool check(AdminL10n t) {
    errors.clear();
    name.check(t, errors);
    errors
      ..set(icon, checkText(t, icon.text, max: 40))
      ..set(
        radius,
        checkWhole(t, radius.text, min: minRadiusM, max: maxRadiusM),
      );
    for (final item in _sentChecklist) {
      item.check(t, errors);
    }
    categoryError = categoryId == null ? t.formRequired : null;
    return errors.isEmpty && categoryError == null;
  }

  /// The draft as the API takes it; call after [check] passed.
  ServiceInput toInput() => ServiceInput(
    categoryId: categoryId!,
    name: name.value,
    iconKey: icon.text.trim(),
    serviceModel: model,
    requiredLevel: level,
    searchRadiusM: int.parse(radius.text.trim()),
    womenProvidersOnly: womenOnly,
    requiresLevel2: requiresLevel2,
    level2Checklist: [for (final item in _sentChecklist) item.value],
    published: published,
  );

  // The checklist is hidden, and cleared on the server, without Level 2.
  List<LocalizedInput> get _sentChecklist =>
      requiresLevel2 ? checklist : const [];

  /// Releases the controllers.
  void dispose() {
    name.dispose();
    icon.dispose();
    radius.dispose();
    for (final item in checklist) {
      item.dispose();
    }
  }
}
