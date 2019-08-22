import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_auth0/flutter_auth0.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/screens/venue_screen.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/errors/simple_error.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:jose/jose.dart';

class AuthUtils {

  /// Identify for the Auth0 application.
  static final auth0ClientKey = "V1jhyoo97eyJCswxErzMb-DWD98DVgZi";

  /// Audience to request access tokens for. Should be API.
  static final String auth0Audience = "api.foriatickets.com";

  /// Domain to send Auth0 requests.
  static final String auth0Domain = "auth.foriatickets.com";

  /// Domain to send Auth0 requests.
  static final String jwtIssuer = "https://auth.foriatickets.com/";

  /// Key name for the access token used in secure storage plugin.
  static final String accessTokenKey = "OAUTH2_ACCESS_TOKEN";

  /// JWT containing user info claims.
  static final String idTokenKey = "OAUTH2_ID_TOKEN";

  /// Key name for the refresh token used in secure storage plugin.
  static final String refreshTokenKey = "OAUTH2_REFRESH_TOKEN";

  static final Auth0 _auth = new Auth0(clientId: auth0ClientKey, domain: auth0Domain);
  static final WebAuth _web = new WebAuth(clientId: auth0ClientKey, domain: auth0Domain);

  static final _storage = new FlutterSecureStorage();

  ///
  /// Returns API client for use in Foria API libs.
  /// This correctly sets the Bearer token for OAuth2 server authentication.
  ///
  Future<ApiClient> obtainForiaApiClient() async {
    JsonWebToken accessToken = await _loadToken(accessTokenKey);

    if (accessToken == null) {
      return null;
    }

    bool isExpired = DateTime.now().compareTo(accessToken.claims.expiry) >= 0;
    if (isExpired) {
      try {
        accessToken = await forceTokenRefresh();
      } catch (ex) {
        throw ex;
      }
    }

    ApiClient apiClient =
    new ApiClient(accessToken: accessToken.toCompactSerialization());

    return apiClient;
  }

  ///
  /// Stores the exchanged tokens securely in storage.
  ///
  Future<void> _storeAuthInfo(dynamic authInfo) async {
    String authToken = authInfo['access_token'];
    String idToken = authInfo['id_token'];
    String refreshToken = authInfo['refresh_token'];

    if (authToken == null || idToken == null) {
      debugPrint("Returned tokens are null. Skipping secure storage.");
      throw new Exception("Returned tokens are null. Skipping secure storage.");
    }

    bool isIdTokenValid = await _validateJwt(idToken, auth0ClientKey);
    bool isAuthTokenValid = await _validateJwt(authToken, auth0Audience);

    if (refreshToken != null) {
      _storage.write(key: refreshTokenKey, value: refreshToken);
    }

    if (!isIdTokenValid || !isAuthTokenValid) {
      debugPrint("Token vaidation failure!");
      throw new Exception("Token failed validation.");
    } else {
      _storage.write(key: accessTokenKey, value: authToken);
      _storage.write(key: idTokenKey, value: idToken);

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

    if (!verified) {
      return false;
    }

    //Validate Claims
    JsonWebTokenClaims claims = jwt.claims;
    debugPrint("JWT Claims: " + claims.toString());

    Iterable<Exception> violations =
    claims.validate(issuer: Uri.parse(jwtIssuer), clientId: audience);

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
    DatabaseUtils.deleteDatabase();
    _storage.deleteAll();

    debugPrint("Logout called. Secrets deleted.");

    _web.clearSession();
    Navigator.pushReplacementNamed(context, '/login');
  }

  ///
  /// Displays the Auth0 login page for OAuth2 PKCE authorization.
  /// When the user returns from browser, the values will be exchanged
  /// for access/refresh tokens.
  ///
  /// On error, a pop-up will be displayed showing a generic error message.
  ///
  void webLogin(BuildContext context) async {
    await _web.authorize(

      audience: auth0Audience,
      scope: 'openid profile email offline_access write:venue_redeem',
    ).then((authInfo) async {
      if (authInfo == null || authInfo['access_token'] == null) {
        debugPrint("Account Blocked. Tokens empty.");
        showErrorAlert(context, loginError);
        return;
      }

      await _storeAuthInfo(authInfo);

      if (await doesUserHaveVenueAccess()) {
        Navigator.pushReplacementNamed(context, VenueScreen.routeName);
      } else {
        Navigator.pushReplacementNamed(context, Home.routeName);
      }
    }).catchError((err) async {
      debugPrint('Auth Error: $err');
      showErrorAlert(context, loginError);
    });
  }

  ///
  /// Checks to see if the logged in account is a venue. If so, we send them to
  /// the venue flow of the app.
  ///
  /// Checks Auth0 permission scope "write:venue_redeem"
  ///
  Future<bool> doesUserHaveVenueAccess() async {
    JsonWebToken jwt = await _loadToken(accessTokenKey);

    if (jwt == null) {
      debugPrint("ERROR: No token found in storage. Not able to check venue.");
      return false;
    }

    Map<String, dynamic> claims = jwt.claims.toJson();
    if (claims != null && claims.containsKey("scope")) {
      String scopeStr = claims["scope"];
      List<String> scopeArr = scopeStr.split(" ");

      for (String scope in scopeArr) {
        if (scope == "write:venue_redeem") {
          debugPrint("User is acessing a venue account.");
          return true;
        }
      }
    }

    return false;
  }

  Future<bool> isUserEmailVerified() async {
    JsonWebToken jwt = await _loadToken(idTokenKey);

    if (jwt == null) {
      debugPrint("ERROR: No token found in storage. Not able to email verify.");
      return false;
    }

    Map<String, dynamic> claims = jwt.claims.toJson();
    if (!claims.containsKey("email_verified")) {
      print("ERROR: email_verified claim missing. Is email scope set?");
      return false;
    }

    debugPrint("Email verified: ${claims["email_verified"]}");
    return claims["email_verified"];
  }

  ///
  /// Checks if the user has a valid access token. If not, the app attempts to
  /// refresh tokens.
  ///
  /// On failure this method will return false.
  /// Expiration check should be skipped if there is no internet to allow offline access.
  ///
  Future<bool> isUserLoggedIn(bool doExpirationCheck) async {
    JsonWebToken jwt = await _loadToken(idTokenKey);

    if (jwt == null) {
      debugPrint("No token found in storage. User is not logged in.");
      return false;
    }

    bool isExpired = DateTime.now().compareTo(jwt.claims.expiry) >= 0;
    if (doExpirationCheck && isExpired) {
      try {
        jwt = await forceTokenRefresh();
      } catch (ex) {
        debugPrint("Exception caught refreshing token. Device might be offline. Msg: ${ex.toString()}");
        return true;
      }
    }

    debugPrint("JWT Claims: ${jwt.claims}");
    debugPrint("User is logged in with a valid token.");
    return true;
  }

  ///
  /// Obtains server access token from storage.
  /// Does not preform validations.
  ///
  Future<JsonWebToken> _loadToken(String tokenName) async {
    String accessTokenStr = await _storage.read(key: tokenName);

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

    return jwt;
  }

  ///
  /// Fetches a new access token for when the current one is expired.
  /// This also validates the new access token, and if valid, replaces the previous token.
  ///
  /// On exception, the user should be logged out.
  /// Returns the new valid access token.
  ///
  Future<JsonWebToken> forceTokenRefresh() async {
    String refreshToken = await _storage.read(key: refreshTokenKey);

    if (refreshToken == null) {
      debugPrint("Refresh token is null when attempting refresh!");
      throw new Exception("Refresh token is null when attempting refresh!");
    }

    var auth0Result;
    try {
      auth0Result = await _auth.refreshToken(refreshToken: refreshToken);
      debugPrint("Refresh Response received: $auth0Result");
    } catch (ex) {
      print("ERROR: Refresh failed on Auth0 side.");
      throw ex;
    }

    await _storeAuthInfo(auth0Result);

    debugPrint("Token refresh complete.");
    return _loadToken(accessTokenKey);
  }
}