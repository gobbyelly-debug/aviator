import 'package:aviator/app.dart';
import 'package:aviator/services/access_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch requires an API-validated OTP access key', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      AviatorMockupApp(accessKeyValidator: _fakeAccessKeyValidator),
    );
    await tester.pump();

    expect(find.text('Enter Access Key'), findsOneWidget);
    expect(find.text('Lipia kwenye lipa namba hii'), findsOneWidget);
    expect(find.text('35 426 9723'), findsOneWidget);
    expect(find.text('10000Tsh week'), findsOneWidget);
    expect(find.text('30000Tsh month'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));

    await _enterOtpAccessKey(tester, 'WRONG1');
    await tester.ensureVisible(find.text('Unlock'));
    await tester.tap(find.text('Unlock'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Invalid or expired access key.'), findsOneWidget);

    await _enterOtpAccessKey(tester, 'ABC123');
    await tester.ensureVisible(find.text('Unlock'));
    await tester.tap(find.text('Unlock'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Enter Access Key'), findsNothing);
    expect(find.text('TIME TO PLAY'), findsOneWidget);
    final generateFinder = find.text('Generate');
    final offlineFinder = find.text('Offline');
    expect(
      generateFinder.evaluate().isNotEmpty ||
          offlineFinder.evaluate().isNotEmpty,
      true,
    );
  });
}

Future<AccessKeyValidationResult> _fakeAccessKeyValidator(
  String accessKey,
) async {
  return AccessKeyValidationResult(
    isValid: accessKey == 'ABC123',
    message: accessKey == 'ABC123' ? null : 'Invalid or expired access key.',
  );
}

Future<void> _enterOtpAccessKey(WidgetTester tester, String accessKey) async {
  for (var index = 0; index < accessKey.length; index++) {
    await tester.enterText(find.byType(TextField).at(index), accessKey[index]);
  }
}
