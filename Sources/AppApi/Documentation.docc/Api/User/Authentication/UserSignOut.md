# Sign out

Signs a user out and deletes all tokens in the current token family.

## Request

    POST /api/v1/sign-out

The refresh token has to be sent as a `BearerToken` with the request.

### Optional query parameters

- term **all**: Wether all token families of this user should be deleted or not.

    If all token families are deleted all sessions of this user will be signed out.

## Response

If the sign out was successful a HTTP Status code `200 - OK` will be returned.

