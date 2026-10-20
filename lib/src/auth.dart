import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuth {
  static const scope = 'https://www.googleapis.com/auth/spreadsheets';
  static const clientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  final GoogleSignIn _sdk = GoogleSignIn.instance;
  GoogleSignInAccount? account;

  Future<void> initialize() async {
    if (clientId.isEmpty) throw StateError('Google OAuth is not configured.');
    await _sdk.initialize(serverClientId: clientId);
    account = await _sdk.attemptLightweightAuthentication();
  }

  Future<void> connect() async {
    account ??= await _sdk.authenticate();
    await account!.authorizationClient.authorizeScopes([scope]);
  }

  Future<String> token() async {
    final user = account;
    if (user == null) throw StateError('Sign in first');
    final auth = await user.authorizationClient.authorizationForScopes([scope]);
    if (auth == null) throw StateError('Google permission expired: reconnect');
    return auth.accessToken;
  }

  Future<void> disconnect() async {
    await _sdk.disconnect();
    account = null;
  }
}
