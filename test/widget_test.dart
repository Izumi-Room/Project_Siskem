import 'package:absensi_triple_des_offline/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen renders Firebase auth form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Absensi Triple DES'), findsOneWidget);
    expect(find.text('Sistem Kehadiran Firebase Cloud'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
  });
}
