import AppApi
import Vapor

extension UserApiController {
    // MARK: - request verification

    func requestVerificationApi(_ req: Request) async throws -> HTTPStatus {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)

        /// Get the user from the path
        let user = try await findBy(identifier(req), on: req.db)

        /// do not allow a verified user to request a verification token and require the model id to be the user id
        guard !user.verified, user.id == authenticatedUser.id else {
            throw Abort(.forbidden)
        }

        /// Create signed verification token
        let signedVerificationToken = try await user.createSignedVerificationToken(on: req)
        try await UserVerifyAccountTemplate.send(for: user, with: signedVerificationToken, on: req)

        return .ok
    }

    // MARK: - Verification

    func verificationApi(_ req: Request) async throws -> User.Account.Detail {
        let user = try req.auth.require(UserAccountModel.self)

        /// check the user with the token is the same one as the user in the request path
        guard try user.requireID() == identifier(req) else {
            throw Abort(.unauthorized)
        }

        /// verify the user
        user.verified = true
        try await user.update(on: req.db)

        /// invalidate the verification token after it has been used by deleting the token family
        try await user.$tokenFamilies.query(on: req.db).filter(\.$tokenType, .equal, .verification).delete(force: true)

        return try await detailOutput(req, user)
    }

    // MARK: - Routes

    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)

        existingModelRoutes
            .grouped(UserJWTVerificationTokenAuthenticator())
            .grouped("verify")
            .post(use: verificationApi)

        existingModelRoutes
            .grouped(UserJWTAccessTokenAuthenticator())
            .grouped(AuthenticatedUser.guardMiddleware())
            .grouped("requestVerification")
            .post(use: requestVerificationApi)
    }
}
