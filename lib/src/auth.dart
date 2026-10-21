import 'package:google_sign_in/google_sign_in.dart';

/// Google authentication for the isolated Payday DEMO.
class GoogleAuth {
  static const scope = 'https://www.googleapis.com/auth/spreadsheets';
  static const clientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  final GoogleSignIn _sdk = GoogleSignIn.instance;
  GoogleSignInAccount? account;
  Future<void>? _initializing;

  /// Safe-to-display diagnostic metadata; never show OAuth access tokens.
  String stage = 'Not initialized';
  String get clientProjectNumber =>
      clientId.contains('-') ? clientId.split('-').first : 'missing';

  // This is shared between silent startup and the sign-in button. Calling
  // initialize concurrently otherwise makes the platform SDK unpredictable.
  Future<void> initialize() => _initializing ??= _initializeOnce();

  Future<void> _initializeOnce() async {
    if (clientId.isEmpty || !clientId.endsWith('.apps.googleusercontent.com')) {
      stage = 'Missing Web OAuth client ID';
      throw StateError('Payday was built without a valid Google Web OAuth client ID.');
    }
    stage = 'Initialize Google Sign-In';
    await _sdk.initialize(serverClientId: clientId);
    stage = 'Restore previous Google session';
    account = await _sdk.attemptLightweightAuthentication();
    stage = 'Ready for account selection';
  }

  Future<void> connect() async {
    await initialize();
    if (account == null) {
      stage = 'Select Google account';
      account = await _sdk.authenticate();
    }
    stage = 'Authorize Sheets permission';
    await account!.authorizationClient.authorizeScopes([scope]);
    stage = 'Google authorization complete';
  }

  Future<String> token() async {
    final user = account;
    if (user == null) throw StateError('Sign in first.');
    final auth = await user.authorizationClient.authorizationForScopes([scope]);
    if (auth == null) throw StateError('Sheets permission missing: reconnect Google.');
    return auth.accessToken;
  }

  Future<void> disconnect() async {
    await _sdk.disconnect();
    account = null;
    stage = 'Disconnected';
  }
}

/// Short, privacy-safe on-screen diagnostics. No tokens, passwords, e-mails,
/// client secrets, or raw provider exception details are displayed.
String explainGoogleSignInError(Object error, String stage) {
  if (error is GoogleSignInException) {
    final code = error.code.name;
    final description = (error.description ?? '').trim();
    final detail = description.isEmpty ? '' : '\nProvider message: $description';
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Google sign-in stopped at: $stage.\n'
          'Code: $code$detail\n'
          'Android Credential Manager can report "canceled" even when '
          'you selected an account. This does not prove you canceled it. '
          'Try the account picker again and check Google Play services '
          'is up to date. If it repeats, check device logs for the '
          'underlying Credential Manager error.';
    }
    if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return 'Google sign-in configuration error at: $stage.\n'
          'Code: $code$detail\n'
          'Check the Web client ID, Android package and SHA-1 certificate.';
    }
    return 'Google sign-in failed at: $stage.\nCode: $code$detail';
  }
  return 'Connection failed at: $stage.\n$error';
}
