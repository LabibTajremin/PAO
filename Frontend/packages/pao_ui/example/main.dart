import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pao_l10n/pao_l10n.dart';
import 'package:pao_ui/pao_ui.dart';

void main() => runApp(
  MaterialApp(
    theme: PaoTheme.light(),
    supportedLocales: PaoLocales.all,
    localizationsDelegates: const [
      PaoL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: const PaoGalleryPage(),
  ),
);
