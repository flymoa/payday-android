import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:payday_mobile/src/auth.dart';

void main() {
  test('Credential Manager cancellation displays stage without blaming user', () {
    const error = GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
      description: 'authentication failed',
    );
    final message = explainGoogleSignInError(error, 'Select Google account');
    expect(message, contains('Select Google account'));
    expect(message, contains('canceled'));
    expect(message, contains('Credential Manager'));
    expect(message, isNot(contains('Your fault')));
  });

  test('Configuration error shows the stage', () {
    const error = GoogleSignInException(
      code: GoogleSignInExceptionCode.clientConfigurationError,
      description: 'serverClientId invalid',
    );
    final message = explainGoogleSignInError(error, 'Initialize Google Sign-In');
    expect(message, contains('Initialize Google Sign-In'));
    expect(message, contains('serverClientId invalid'));
  });

  test('Network errors are distinguishable from Google account selection', () {
    final message = explainGoogleSignInError(
      StateError('Network unavailable'), 'Authorize Sheets permission');
    expect(message, contains('Authorize Sheets permission'));
    expect(message, contains('Network unavailable'));
  });
}
