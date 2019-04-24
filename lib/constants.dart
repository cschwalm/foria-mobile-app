/// Identify for the Auth0 application.
const auth0ClientKey = "V1jhyoo97eyJCswxErzMb-DWD98DVgZi";

/// Audience to request access tokens for. Should be API.
const String auth0Audience = "api.foriatickets.com";

/// Domain to send Auth0 requests.
const String auth0Domain = "foriatickets.auth0.com";

/// Domain to send Auth0 requests.
const String JWTIssuer = "https://foriatickets.auth0.com/";

/// Key name for the access token used in secure storage plugin.
const String accessTokenKey = "OAUTH2_ACCESS_TOKEN";

/// JWT containing user info claims.
const String idTokenKey = "OAUTH2_ID_TOKEN";

/// Key name for the refresh token used in secure storage plugin.
const String refreshTokenKey = "OAUTH2_REFRESH_TOKEN";