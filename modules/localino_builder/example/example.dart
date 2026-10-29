// Demonstrates localino_builder's typed key generator over in-memory locale
// maps — no API token, no network, no Flutter. Run with:
//
//   dart run example/example.dart
//
// In a real project the builder fetches these maps from the Localino API and
// writes the generated source to lib/generated/localino_keys.dart when
// `generate_keys: true` is set (see README).

import 'package:localino_builder/src/key_generator.dart';
import 'package:localino_builder/src/key_parser.dart';

void main() {
  // Two locales, as the builder would decode them from the API. `cs_CZ` is
  // missing `action_delete_locale` on purpose to show the ⚠ annotation.
  final localesByCode = <String, Map>{
    'en_US': {
      'action_add': 'Add',
      'action_delete_locale': 'Delete locale',
      'version': 'Version: {version} ({number})',
      'onboard_card_1': {'title': 'Get started', 'note': 'Swipe to continue'},
      'menu_tabs': ['Home', 'Search', 'Profile'],
    },
    'cs_CZ': {
      'action_add': 'Přidat',
      'version': 'Verze: {version} ({number})',
      'onboard_card_1': {'title': 'Začínáme', 'note': 'Přejeďte'},
      'menu_tabs': ['Domů', 'Hledat', 'Profil'],
    },
  };

  // Default locale drives previews + the key universe for missing detection.
  // The builder resolves this from setup.json (init.default_locale ?? first).
  final keys = parseLocalinoKeys(localesByCode, defaultLocale: 'en_US');
  final source = generateLocalinoKeys(keys);

  print(source);
  // Call sites then become: Localize.i(LocalinoKeys.action_add)
}
