# Verify email

Verifies the email address of an user.

## Request 

    POST /api/v1/user/accounts/<user-id>/verify

The verification token the user received has to be sent as a `BearerToken` with the request.

> Note: The user gets a verification link with the token embedded after creating an account. To request an additional email verification link see: <doc:UserRequestVerifyEmail>.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<user-id>",
    "name": "<user-name>",
    "school": "<user-school>",
}
```

## See Also

* ``User/Account/Detail``
