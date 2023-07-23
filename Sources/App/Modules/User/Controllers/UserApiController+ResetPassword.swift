import AppApi
import Vapor

extension UserApiController {
    // MARK: - request reset password

    @AsyncValidatorBuilder
    func requestResetPasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.email("email")
    }

    func requestResetPasswordApi(_ req: Request) async throws -> HTTPStatus {
        try await RequestValidator(requestResetPasswordValidators()).validate(req)
        let input = try req.content.decode(User.Account.ResetPasswordRequest.self)

        guard let user = try await UserAccountModel.query(on: req.db)
            .filter(\.$email, .equal, input.email)
            .first()
        else {
            throw Abort(.notFound)
        }

        /// Create signed verification token
        let signedVerificationToken = try await user.createSignedVerificationToken(on: req)
        try await UserRequestPasswordResetMail.send(for: user, with: signedVerificationToken, on: req)

        return .ok
    }

    // MARK: - reset password

    @AsyncValidatorBuilder
    func resetPasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("newPassword")
    }

    func resetPasswordApi(_ req: Request) async throws -> User.Account.Detail {
        let user = try req.auth.require(UserAccountModel.self)

        /// check the user with the token is the same one as the user in the request path
        guard try user.requireID() == identifier(req) else {
            throw Abort(.unauthorized)
        }

        try await RequestValidator(resetPasswordValidators()).validate(req)
        let input = try req.content.decode(User.Account.ResetPassword.self)

        /// change the password if the user is verified and the token therefore correct
        try user.setPassword(to: input.newPassword, on: req)

        /// User is verified after password reset since he has access to his email
        user.verified = true
        try await user.update(on: req.db)

        /// invalidate the verification token after it has been used by deleting the token family
        try await user.$tokenFamilies.query(on: req.db).filter(\.$tokenType, .equal, .verification).delete(force: true)

        return try await detailOutput(req, user)
    }

    // MARK: - Routes

    func setupResetPasswordRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)

        baseRoutes
            .grouped(ApiModel.pathIdComponent)
            .grouped(UserJWTVerificationTokenAuthenticator())
            .grouped("resetPassword")
            .post(use: resetPasswordApi)

        baseRoutes
            .grouped(UserJWTAccessTokenAuthenticator())
            .grouped("resetPassword")
            .post(use: requestResetPasswordApi)
    }
}
