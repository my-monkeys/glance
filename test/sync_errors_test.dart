import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/sync/sync_api.dart';

void main() {
  test('un refus d\'inscription dit pourquoi', () {
    expect(signUpErrorMessage('PASSWORD_TOO_SHORT'), contains('8 caractères'));
    expect(signUpErrorMessage('INVALID_EMAIL'), 'Adresse e-mail invalide.');
    expect(signUpErrorMessage('USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL'),
        contains('connectez-vous'));
    expect(signUpErrorMessage('USER_ALREADY_EXISTS'), contains('connectez-vous'));
  });

  test('un code inconnu ou absent garde le message générique', () {
    expect(signUpErrorMessage(null), 'Impossible de créer le compte.');
    expect(signUpErrorMessage('INTERNAL'), 'Impossible de créer le compte.');
  });
}
