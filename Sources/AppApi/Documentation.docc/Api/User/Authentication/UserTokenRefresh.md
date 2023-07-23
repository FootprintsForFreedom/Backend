# Refresh tokens

Returns a new access and refresh token pair.

## Request

    POST /api/v1/token-refresh

The own refresh token has to be sent as a `BearerToken` with the request.

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

The access token returned can be used for accessing content and will be valid for 15 minutes. To request a new access token the refresh token is used in this request.

> Important: As soon as a new refresh token is created all older refresh tokens in this token family will be invalid. A token family is usually limited to a device or browser since each login creates a new token family. 

## See Also

* ``User/Token/Detail``
* ``User/Account/Detail``
* ``User/Role``
