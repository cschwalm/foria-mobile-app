import 'dart:convert';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_auth0/flutter_auth0.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foria/main.dart';
import 'package:foria/screens/home.dart';
import 'package:foria/screens/intro_screen_one.dart';
import 'package:foria/screens/login.dart';
import 'package:foria/utils/database_utils.dart';
import 'package:foria/utils/strings.dart';
import 'package:foria/widgets/errors/simple_error.dart';
import 'package:foria_flutter_client/api.dart';
import 'package:jose/jose.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'configuration.dart';

class AuthUtils {

  /// Key name for the access token used in secure storage plugin.
  static final String accessTokenKey = "OAUTH2_ACCESS_TOKEN";

  /// JWT containing user info claims.
  static final String idTokenKey = "OAUTH2_ID_TOKEN";

  /// Key name for the refresh token used in secure storage plugin.
  static final String refreshTokenKey = "OAUTH2_REFRESH_TOKEN";

  static final Auth0 _auth = new Auth0(clientId: Configuration.auth0ClientKey, baseUrl: Configuration.auth0BaseUrl);

  static final _storage = new FlutterSecureStorage();

  static final FirebaseAnalytics _analytics = new FirebaseAnalytics();

  /// Data from logged in user
  User _user;
  bool _isVenue;

  ///
  /// May be null if user has not logged in.
  ///
  User get user => _user;
  bool get isVenue => _isVenue;

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
    new ApiClient(basePath: Configuration.apiBasePath,accessToken: accessToken.toCompactSerialization());

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
      log("Returned tokens are null. Skipping secure storage.");
      throw new Exception("Returned tokens are null. Skipping secure storage.");
    }

    bool isIdTokenValid = await _validateJwt(idToken, Configuration.auth0ClientKey);
    bool isAuthTokenValid = await _validateJwt(authToken, Configuration.auth0Audience);

    if (refreshToken != null) {
      _storage.write(key: refreshTokenKey, value: refreshToken);
    }

    if (!isIdTokenValid || !isAuthTokenValid) {
      log("Token vaidation failure!");
      throw new Exception("Token failed validation.");
    } else {
      _storage.write(key: accessTokenKey, value: authToken);
      _storage.write(key: idTokenKey, value: idToken);

      log("Tokens stored in secure storage.");
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
      log("Failed to parse JWT! - Error: $e");
      return false;
    }

    //Validate token
    final String keyStr = await rootBundle.loadString(Configuration.jwksPath);
    final jwks = json.decode(keyStr);

    var keyStore = new JsonWebKeyStore()
      ..addKey(JsonWebKey.fromJson(jwks));

    bool verified = await jwt.verify(keyStore);

    if (!verified) {
      return false;
    }

    //Validate Claims
    JsonWebTokenClaims claims = jwt.claims;

    Iterable<Exception> violations =
    claims.validate(issuer: Uri.parse(Configuration.jwtIssuer), clientId: audience);

    if (violations.isNotEmpty) {
      log("JWT Claim Violations: $violations");
      return false;
    }

    return true;
  }

  ///
  /// Preforms all required steps to log the user out.
  ///
  /// WARNING: This deletes all data in the secure storage.
  ///
  Future<void> logout() async {
    await DatabaseUtils.deleteDatabase();
    await _storage.deleteAll();
    await _auth.webAuth.clearSession(federated: false);
    log("Logout called. Secrets deleted.");

    setupDependencies();
    await navigatorKey.currentState.pushNamedAndRemoveUntil(Login.routeName, ModalRoute.withName('/'));
  }

  ///
  /// Displays the Auth0 login page for OAuth2 PKCE authorization.
  /// When the user returns from browser, the values will be exchanged
  /// for access/refresh tokens.
  ///
  /// On error, a pop-up will be displayed showing a generic error message.
  ///
  void webLogin(BuildContext context) async {

    Map<String, dynamic> options = new Map<String, dynamic>();
    options['audience'] = Configuration.auth0Audience;
    options['scope'] = 'openid profile email offline_access write:venue_redeem read:venue';

    await _auth.webAuth.authorize(options).then((authInfo) async {

      if (authInfo == null || authInfo['access_token'] == null) {
        log("Account Blocked. Tokens empty.");
        showErrorAlert(context, loginError);
        return;
      }

      await _storeAuthInfo(authInfo);

      // Populates user info for first user login.
      if (!await isUserLoggedIn(false)) {
        log("User failed login check.");
        showErrorAlert(context, loginError);
        return;
      }

      SharedPreferences pref = await SharedPreferences.getInstance();
      if (pref.getBool('viewedForiaIntro') == null) {
        pref.setBool('viewedForiaIntro', false);
      }

      if (await doesUserHaveVenueAccess()) {
        Navigator.of(context).pushReplacementNamed(Home.routeName);
      } else if (pref.getBool('viewedForiaIntro')) {
        Navigator.of(context).pushReplacementNamed(Home.routeName);
      } else {
        Navigator.pushReplacementNamed(context, IntroScreenOne.routeName);
      }
    }).catchError((err) async {
      log('Auth Error: ${err.toString()}');
      showErrorAlert(context, loginError, _auth.webAuth.clearSession);
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
      log("ERROR: No token found in storage. Not able to check venue.", level: Level.WARNING.value);
      _isVenue = false;
      return false;
    }

    Map<String, dynamic> claims = jwt.claims.toJson();
    if (claims != null && claims.containsKey("scope")) {
      String scopeStr = claims["scope"];
      List<String> scopeArr = scopeStr.split(" ");

      for (String scope in scopeArr) {
        if (scope == "write:venue_redeem") {
          log("User is acessing a venue account.");
          _isVenue = true;
          return true;
        }
      }
    }

    _isVenue = false;
    return false;
  }

  Future<bool> isUserEmailVerified() async {
    JsonWebToken jwt = await _loadToken(idTokenKey);

    if (jwt == null) {
      log("ERROR: No token found in storage. Not able to email verify.", level: Level.WARNING.value);
      return false;
    }

    Map<String, dynamic> claims = jwt.claims.toJson();
    if (!claims.containsKey("email_verified")) {
      log("ERROR: email_verified claim missing. Is email scope set?", level: Level.SEVERE.value);
      return false;
    }

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
      log("No token found in storage. User is not logged in.");
      return false;
    }

    bool isExpired = DateTime.now().compareTo(jwt.claims.expiry) >= 0;
    if (doExpirationCheck && isExpired) {
      try {
        jwt = await forceTokenRefresh();
      } catch (ex) {
        log("Exception caught refreshing token. Device might be offline. Msg: ${ex.toString()}", level: Level.WARNING.value);
        return true;
      }
    }

    // Setup user data.
    _user = new User();
    _user.id = jwt.claims.subject;
    _user.email = jwt.claims["email"];
    _user.firstName = jwt.claims["given_name"];
    _user.lastName = jwt.claims["family_name"];

    _analytics.setUserId(_user.id);
    return true;
  }

  ///
  /// Obtains server access token from storage.
  /// Does not preform validations.
  ///
  Future<JsonWebToken> _loadToken(String tokenName) async {
    String accessTokenStr = await _storage.read(key: tokenName);

    if (accessTokenStr == null) {
      log("User is not logged in. No access token found.");
      return null;
    }

    JsonWebToken jwt;
    try {
      jwt = new JsonWebToken.unverified(accessTokenStr);
    } catch (e) {
      log("Failed to parse JWT on login! - Error: $e", level: Level.WARNING.value);
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
      log("Refresh token is null when attempting refresh!", level: Level.WARNING.value);
      throw new Exception("Refresh token is null when attempting refresh!");
    }

    final params = {
      'refreshToken': refreshToken
    };
    var auth0Result;
    try {
      auth0Result = await _auth.auth.refreshToken(params);
    } catch (ex) {
      log("ERROR: Refresh failed on Auth0 side.", level: Level.WARNING.value);
      throw ex;
    }

    await _storeAuthInfo(auth0Result);

    log("Token refresh complete.");
    return _loadToken(accessTokenKey);
  }
}