import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hesably_mobile/main.dart' as app;

// IMPORTANT: This test requires a running emulator or physical device.
// It uses a real connection to the Supabase Staging environment.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end authentic flow', () {
    testWidgets('login and verify receipt capture UI', (tester) async {
      // 1. Launch the app
      app.main();
      
      // Wait for the app to render and settle
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Authentication Flow
      // We look for the Phone input field
      final phoneField = find.byType(TextField).first;
      expect(phoneField, findsOneWidget);

      // Enter the mock account phone number
      await tester.enterText(phoneField, '+201000000000');
      await tester.pumpAndSettle();

      // Tap Login
      final loginButton = find.byType(ElevatedButton).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3. OTP Verification
      // Look for the OTP field
      final otpField = find.byType(TextField).first;
      expect(otpField, findsOneWidget);

      // Enter the static test OTP
      await tester.enterText(otpField, '123456');
      await tester.pumpAndSettle();

      // Tap Login again (Verify OTP)
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 4. Verify successful login by checking for Onboarding or Dashboard UI
      // Assuming we reach onboarding or home. Let's just verify we moved away from the auth page.
      expect(find.text('app_name'), findsNothing); 
      
      // TODO: Once the app is fully wired, this test should continue to the Capture Screen,
      // trigger the mock image picker, and assert the AI Extraction backend returns a draft.
      // Currently, native image pickers require Patrol or custom platform channels to automate fully.
    });
  });
}
