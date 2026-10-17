import 'package:flutter/material.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/l10n/generated/customer_localizations.dart';

/// The name of an address [label].
String addressLabelName(CustomerL10n t, AddressLabel label) => switch (label) {
  AddressLabel.home => t.locLabelHome,
  AddressLabel.office => t.locLabelOffice,
  AddressLabel.other => t.locLabelOther,
};

/// The icon of an address [label].
IconData addressLabelIcon(AddressLabel label) => switch (label) {
  AddressLabel.home => Icons.home_outlined,
  AddressLabel.office => Icons.work_outline,
  AddressLabel.other => Icons.place_outlined,
};

/// One line describing a saved address.
String addressLine(Address a) => [
  a.line1,
  if (a.area case final area? when area.isNotEmpty) area,
].join(', ');
