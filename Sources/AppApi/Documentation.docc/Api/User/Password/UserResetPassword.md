# Reset password

Resets the user password when it has been forgotten.

## Request

    POST /api/v1/users/accounts/<user-id>/resetPassword

The verification token the user received has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **newPassword**: The new password set by the user for his account.

The parameters can be either sent as `application/json` or `multipart/form-data`.

> Note: The new password needs to contain at least
>
> * one uppercase letter
> * one lowercase letter
> * one digit
> * six characters in total

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

* ``User/Account/ResetPassword``
* ``User/Account/Detail``
