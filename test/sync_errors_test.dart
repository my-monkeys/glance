import 'package:flutter_test/flutter_test.dart';
import 'package:glance/l10n/app_localizations_fr.dart';
import 'package:glance/state/sync.dart';
import 'package:glance/ui/settings/sync_screen.dart';

final _l10n = AppLocalizationsFr();

String _text(String? code) => syncMessageText(_l10n, signUpMessageFor(code));

void main() {
  test('un refus d\'inscription dit pourquoi', () {
    expect(_text('PASSWORD_TOO_SHORT'), contains('8 caractères'));
    expect(_text('INVALID_EMAIL'), 'Adresse e-mail invalide.');
    expect(_text('USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL'),
        contains('connectez-vous'));
    expect(_text('USER_ALREADY_EXISTS'), contains('connectez-vous'));
  });

  test('un code inconnu ou absent garde le message générique', () {
    expect(_text(null), 'Impossible de créer le compte.');
    expect(_text('INTERNAL'), 'Impossible de créer le compte.');
  });
}
