enum Environment { STAGING, PROD }

class Configuration {
  static Map<String, dynamic> _config;

  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.STAGING:
        _config = _Config.stagingConstants;
        break;
      case Environment.PROD:
        _config = _Config.prodConstants;
        break;
    }
  }

  /// Identify for the Auth0 application.
  static get auth0ClientKey {
    return _config[_Config.auth0ClientKey];
  }

  /// Audience to request access tokens for. Should be API.
  static get auth0Audience {
    return _config[_Config.auth0Audience];
  }

  /// Domain to send Auth0 requests.
  static get auth0BaseUrl {
    return _config[_Config.auth0BaseUrl];
  }

  /// Domain to send Auth0 requests.
  static get jwtIssuer {
    return _config[_Config.jwtIssuer];
  }

  static get apiBasePath {
    return _config[_Config.apiBasePath];
  }

  static get jwksPath {
    return _config[_Config.jwksPath];
  }

}

class _Config {

  static const auth0ClientKey = 'auth0ClientKey';
  static const auth0Audience = 'auth0Audience';
  static const auth0BaseUrl = 'auth0BaseUrl';
  static const jwtIssuer = 'jwtIssuer';
  static const apiBasePath = 'apiBasePath';
  static const jwksPath = 'jwksPath';


  static Map<String, dynamic> stagingConstants = {
    auth0ClientKey: 'QilsQNvoUwUVAMkkFAg4mBPgtrK9HwaU',
    auth0Audience: 'api.foriatickets.com',
    auth0BaseUrl: 'https://foriatickets-test.auth0.com',
    jwtIssuer: 'https://foriatickets-test.auth0.com/',
    apiBasePath: 'https://test-api.foriatickets.com/v1',
    jwksPath: 'assets/jwks_staging.json',
  };

  static Map<String, dynamic> prodConstants = {

    auth0ClientKey: 'V1jhyoo97eyJCswxErzMb-DWD98DVgZi',
    auth0Audience: 'api.foriatickets.com',
    auth0BaseUrl: 'https://auth.foriatickets.com',
    jwtIssuer: 'https://auth.foriatickets.com/',
    apiBasePath: 'https://api.foriatickets.com/v1',
    jwksPath: 'assets/jwks_prod.json',
  };
}

