import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_auth0/flutter_auth0.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/constants.dart';
import 'package:foria/strings.dart';
import 'package:jose/jose.dart';

final Auth0 _auth = new Auth0(clientId: auth0ClientKey, domain: auth0Domain);
final WebAuth _web = new WebAuth(clientId: auth0ClientKey, domain: auth0Domain);

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

    final storage = new FlutterSecureStorage();
    storage.write(key: accessTokenKey, value: authToken);
    storage.write(key: idTokenKey, value: idToken);
    storage.write(key: refreshTokenKey, value: refreshToken);

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

  final storage = new FlutterSecureStorage();
  storage.deleteAll();

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