import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/auth/auth_repository.dart';

void main() {
  test('first name is the first word of the name', () {
    expect(
      const Account(uid: 'a', name: 'Rider One', isRider: false).firstName,
      'Rider',
    );
    expect(
      const Account(uid: 'a', name: '  Solo  ', isRider: false).firstName,
      'Solo',
    );
    expect(const Account(uid: 'a', name: '', isRider: false).firstName, '');
  });
}
