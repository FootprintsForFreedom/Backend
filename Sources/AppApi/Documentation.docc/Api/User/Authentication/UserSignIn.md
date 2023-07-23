# Sign in

Signs a user in and returns a token.

## Request

    POST /api/v1/sign-in

### Input parameters

The following parameters have to be sent with the request for it to be successful:
 
- term **email**: The user's email address.
- term **password**: The password set by the user for his account. 

The parameters can be either sent as `application/json`, `multipart/form-data` or using the HTTP Basic Auth header.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<token-id>",
    "access_token": "<access-token>",
    "refresh_token": "<refresh-token>",
    "user": {
        "id": "<user-id>",
        "name": "<user-name>",
        "email": "<user-email>",
        "school": "<user-school>",
        "verified": <user-verified>,
        "role": "<user-role>"
    }
}
```

> Note: The user object is the same as the one returned when getting the own user: <doc:UserDetailSelf>.

The access token returned can be used for accessing content and will be valid for 15 minutes. To request a new access token the refresh token is used. For details see <doc:UserTokenRefresh>. 

The sign in creates a new token family.

## See Also

* ``User/Account/Login``
* ``User/Token/Detail``
* ``User/Account/Detail``
* ``User/Role``
