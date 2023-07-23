import AppApi
import Vapor

extension Request {
    func onlyForVerifiedUser() async throws {
        /// Require user to be signed in
        let user = try auth.require(AuthenticatedUser.self)
        /// require  the user to be a admin or higher
        guard user.verified else {
            throw Abort(.forbidden)
        }
    }

    func onlyFor(_ role: User.Role) async throws {
        /// Require user to be signed in
        let user = try auth.require(AuthenticatedUser.self)
        /// require  the user to be a admin or higher
        guard user.role >= role else {
            throw Abort(.forbidden)
        }
    }

    func onlyFor(_ user: UserAccountModel, or role: User.Role) async throws {
        /// Require user to be signed in
        let requestingUser = try auth.require(AuthenticatedUser.self)
        /// require the model id to be the user id or the user to be an moderator
        guard requestingUser.id == user.id || requestingUser.role >= role else {
            throw Abort(.forbidden)
        }
    }
}
