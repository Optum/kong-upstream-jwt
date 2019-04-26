# Kong Upstream JWT Plugin
## Overview
This plugin will add a signed JWT into the HTTP Header `JWT` of proxied requests through the Kong gateway. The purpose of this, is to provide means of _Authentication_, _Authorization_ and _Non-Repudiation_ to API providers (APIs for which Kong is a gateway).

In short, API Providers need a means of cryptographically validating that requests they receive were A. proxied by Kong, and B. not tampered with during transmission from Kong -> API Provider. This token accomplishes both as follows:
1. **Authentication** & **Authorization** - Provided by means of JWT signature validation. The API Provider will validate the signature on the JWT token (which is generating using Kong's RSA x509 private key), using Kong's public key. This public key can be maintained in a keystore, or sent with the token - provided API providers validate the signature chain against their truststore.
2. **Non-Repudiation** - SHA256 is used to hash the body of the HTTP Request Body, and the resulting digest is included in the `payloadhash` element of the JWT body. API Providers will take the SHA256 hash of the HTTP Request Body, and compare the digest to that found in the JWT. If they are identical, the request remained intact during transmission.

## Supported Kong Releases
Kong >= 0.12.x 

## Installation
Recommended:
```
$ luarocks install kong-upstream-jwt
```
Other:
```
$ git clone https://github.com/Optum/kong-upstream-jwt.git /path/to/kong/plugins/kong-upstream-jwt
$ cd /path/to/kong/plugins/kong-upstream-jwt
$ luarocks make *.rockspec
```

## JWT Token
The following is an example of the contents of the decoded JWT token:

**Header:**
```json
{
  "x5c": ["...der-encoded cert data..."],
  "alg": "RS256",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "sub": "consumer-id", // Unique Consumer ID
  "aud": "audience", // Only set if audience configuration variable available
  "iss": "issuer", // Only set if issuer configuration variable available
  "iat": 1550258274, // Only set if issuer configuration variable available
  "exp": 1550258334, // 1 minute exp time,
  "jti": "d4f10edb-c4f0-47d3-b7e0-90a30a885a0b", // Unique to every request - UUID
  "username": "consumer-username", // Consumer Username
  "payloadhash": "...sha256 hash of request payload..."
}
```

## Configuration

### Private and Public Keys
The plugin requires that Kong's private key be accessible in order to sign the JWT. [We also include the x509 cert in the `x5c` JWT Header for use by API providers to validate the JWT](https://tools.ietf.org/html/rfc7515#section-4.1.6).

**Add the following to _nginx.conf_:**
```
private_key_location = "/path/to/kong/ssl/privatekey.key"
public_key_location = "/path/to/kong/ssl/kongpublickey.cer"
```
The first contains the path to your .key file, the second specifies the path to your public key in DER format .cer file.

#### Backwards Compatibility
To maintain backwards compatibility, support for passing the key locations through environment variables is also available.  We access these via Kong's overriding environment variables `KONG_SSL_CERT_KEY` for the private key as well as `KONG_SSL_CERT_DER` for the public key.

**If not already set, these can be done so as follows:**
```
$ export KONG_SSL_CERT_KEY="/path/to/kong/ssl/privatekey.key"
$ export KONG_SSL_CERT_DER="/path/to/kong/ssl/kongpublickey.cer"
```

**One last step** is to make the environment variables accessible by an nginx worker. To do this, simply add these line to your _nginx.conf_
```
env KONG_SSL_CERT_KEY;
env KONG_SSL_CERT_DER;
```

### JWT Issuer
[JWT Issuer](https://tools.ietf.org/html/rfc7519#section-4.1.1) allows for the `iss` field to be set within the `JWT` token.

**Add the following to _nginx.conf_:**
```
issuer = "issuer"
```

### JWT Audience
[JWT Audience](https://tools.ietf.org/html/rfc7519#section-4.1.3) allows for the `aud` field to be set within the `JWT` token.

**Add the following to _nginx.conf_:**
```
audience = "audience"
```

More information about JWT claims can be found [here](https://tools.ietf.org/html/rfc7519#section-4)

## Maintainers
[jeremyjpj0916](https://github.com/jeremyjpj0916)  
[rsbrisci](https://github.com/rsbrisci)  

Feel free to open issues, or refer to our [Contribution Guidelines](https://github.com/Optum/kong-upstream-jwt/blob/master/CONTRIBUTING.md) if you have any questions.
