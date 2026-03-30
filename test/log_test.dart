import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

void main(){
  late  LoginController controller;

  setUp(() {
    controller = LoginController();
  });

  test('Login berhasil dengan username dan password benar', () {
    // Arrange
    const username = 'gilang';
    const password = 'ohh';

    // Act
    final result = controller.login(username, password);

    // Expect
    expect(result, isNotNull);
    expect(result!.username, username);
    expect(result.role, 'Asisten');
  });

  test('Login gagal karena password salah', () {
    // Arrange
    const username = 'gilang';
    const password = 'salah';

    // Act 
    final result = controller.login(username, password);

    // Expect
    expect(result, isNull);
  });

  test('Login gagal karena usernam tidak ada di database', () {
    // Arrange
    const username = 'Surya';
    const password = 'ohh';

    // Act

    final result = controller.login(username, password);
    
    // Expect
    expect(result, isNull);
  });
}