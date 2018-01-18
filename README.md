# Kong Upstream JWT Plugin
## Overview
This plugin will a signed JWT into the HTTP Header `JWT` of proxied requests through the Kong gateway. The purpose of this, is to provide means of _Authentication_, _Authorization_ and _Non-Repudiation_ to API providers (APIs for which Kong is a gateway).

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

## Configuration
The plugin requires that Kong's private key be accessible in order to sign the JWT. We access this via Kong's overriding environment variable `KONG_SSL_CERT_KEY`. This is the  environment variable can be set as either a windows or Linux environment variable and must contain the path to your .key file. It is used by Kong to override the contents of Kong's config file, if your path is also set there.

If not already set, it can be done so as follows:
```
$ export KONG_SSL_CERT_KEY="/path/to/kong/private/key.key"
```

**One last step** is to make the environment variable accessible by an nginx worker. To do this, simply add this line to your _nginx.conf_
```
env KONG_SSL_CERT_KEY;
```


Feel free to open issues, or refer to our Contribution Guidelines if you have any questions.
