import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_auth0/flutter_auth0.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/utils/constants.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:jose/jose.dart';

final Auth0 _auth = new Auth0(clientId: auth0ClientKey, domain: auth0Domain);
final WebAuth _web = new WebAuth(clientId: auth0ClientKey, domain: auth0Domain);

final _storage = new FlutterSecureStorage();

Future<ApiClient> obtainForiaApiClient() async {

  JsonWebToken accessToken = await _loadAccessToken();
  ApiClient apiClient = new ApiClient(accessToken: accessToken.toCompactSerialization());
  return apiClient;
}

/// Shows the user a generic error message.
void showErrorAlert(BuildContext context, String error) {

  Widget okButton = FlatButton(

    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  AlertDialog alert = AlertDialog(
    title: Text("Login Failure"),
    content: Text(error),
    actions: [
      okButton,
    ],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

///
/// Stores the exchanged tokens securely in storage.
///
Future<void> _storeAuthInfo(dynamic authInfo) async {

  print('Auth0 Grant Response: $authInfo');
  String authToken = authInfo['access_token'];
  String idToken = authInfo['id_token'];
  String refreshToken = authInfo['refresh_token'];

  if (authToken == null || refreshToken == null) {
    debugPrint("Returned tokens are null. Skipping secure storage.");
    throw new Exception("Returned tokens are null. Skipping secure storage.");
  }

  bool isIdTokenValid = await _validateJwt(idToken, auth0ClientKey);
  bool isAuthTokenValid = await _validateJwt(authToken, auth0Audience);

  if (!isIdTokenValid || !isAuthTokenValid || refreshToken == null) {
    debugPrint("Token vaidation failure!");
    throw new Exception("Token failed validation.");

  } else {

    _storage.write(key: accessTokenKey, value: authToken);
    _storage.write(key: idTokenKey, value: idToken);
    _storage.write(key: refreshTokenKey, value: refreshToken);

    debugPrint("Tokens stored in secure storage.");
  }
}

///
/// Validates that the supplied JWT is valid format,
/// is signed and verified using Auth0 domain's private key,
/// and that the claims are valid including expiration.
///
Future<bool> _validateJwt(String encodedJwt, String audience) async {

  // create a JsonWebSignature from the encoded string
  JsonWebToken jwt;
  try {
    jwt = new JsonWebToken.unverified(encodedJwt);
  } catch (e) {
    debugPrint("Failed to parse JWT! - Error: $e");
    return false;
  }

  //Validate token
  final String keyStr = await rootBundle.loadString("assets/jwks.json");
  final jwks = json.decode(keyStr);

  var keyStore = new JsonWebKeyStore()
    ..addKey(JsonWebKey.fromJson(jwks));

  bool verified = await jwt.verify(keyStore);
  debugPrint("JWT Verified: $verified");

  if (!verified) {
    return false;
  }

  //Validate Claims
  JsonWebTokenClaims claims = jwt.claims;
  debugPrint("JWT Claims: " + claims.toString());

  Iterable<Exception> violations = claims.validate(issuer: Uri.parse(JWTIssuer), clientId: audience);

  if (violations.isNotEmpty) {
    debugPrint("JWT Claim Violations: $violations");
    return false;
  }

  return true;
}

///
/// Preforms all required steps to log the user out.
///
/// WARNING: This deletes all data in the secure storage.
///
void logout(BuildContext context) {

  _storage.deleteAll();

  debugPrint("Logout called. Secrets deleted.");
  Navigator.pushReplacementNamed(context, '/login');
}

///
/// Displays the Auth0 login page for OAuth2 PKCE authorization.
/// When the user returns from browser, the values will be exchanged
/// for access/refresh tokens.
///
/// On error, a pop-up will be displayed showing a generic error message.
///
void webLogin(BuildContext context) {

  _web.authorize(

    audience: auth0Audience,
    scope: 'openid profile offline_access',

  ).then((authInfo) => _storeAuthInfo(authInfo)
  ).then((_) {

    // Navigate to the main screen if login passed.
    debugPrint("Auth Passed. Navigating to home screen");
    Navigator.pushReplacementNamed(context, '/home');

  }).catchError((err) {

    debugPrint('Auth Error: $err');
    showErrorAlert(context, loginError);
    return;
  });
}

///
/// Checks if the user has a valid access token. If not, the app attempts to
/// refresh tokens.
///
/// On failure this method will return false.
///
Future<bool> isUserLoggedIn() async {

    JsonWebToken jwt = await _loadAccessToken();

    if (jwt == null) {
      return false;
    }

    bool isExpired = DateTime.now().compareTo(jwt.claims.expiry) >= 0;
    if (isExpired) { //Expiration check should be skipped if there is no internet to allow offline access.

      try {
        jwt = await _refreshToken();
      } catch (ex) {
        debugPrint("Exception caught refreshing token. Msg: $ex");
        return false;
      }
    }

    debugPrint("User is logged in with a valid token.");
    return true;
}

///
/// Obtains token from storage. Does NOT check for validity.
///
Future<JsonWebToken> _loadAccessToken() async {

  String accessTokenStr = await _storage.read(key: accessTokenKey);

  if (accessTokenStr == null) {
    debugPrint("User is not logged in. No access token found.");
    return null;
  }

  JsonWebToken jwt;
  try {
    jwt = new JsonWebToken.unverified(accessTokenStr);
  } catch (e) {
    debugPrint("Failed to parse JWT on login! - Error: $e");
    return null;
  }

  bool isExpired = DateTime.now().compareTo(jwt.claims.expiry) >= 0;
  if (isExpired) {
    jwt = await _refreshToken();
  }

  return jwt;
}

///
/// Fetches a new access token for when the current one is expired.
/// This also validates the new access token, and if valid, replaces the previous token.
///
/// On exception, the user should be logged out.
/// Returns the new valid access token.
///
Future<JsonWebToken> _refreshToken() async {

  String refreshToken = await _storage.read(key: refreshTokenKey);
  if (refreshToken == null) {

    debugPrint("Refresh token is null when attempting refresh!");
    throw new Exception("Refresh token is null when attempting refresh!");
  }
  
  var auth0Result = await _auth.refreshToken(refreshToken: refreshToken);
  debugPrint("Refresh Response received: $auth0Result");

  String authToken = auth0Result['access_token'];

  bool isAuthTokenValid = await _validateJwt(authToken, auth0Audience);
  if (!isAuthTokenValid) {
    debugPrint("Returned auth token is not valid!");
    throw new Exception("Returned auth token is not valid!");
  }

  _storage.write(key: accessTokenKey, value: authToken);
  debugPrint("Token refresh complete.");
  return _loadAccessToken();
}