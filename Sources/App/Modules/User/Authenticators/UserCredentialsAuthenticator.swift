import AppApi
import Fluent
import Vapor

extension User.Account.Login: Content { }

struct UserCredentialsAuthenticator: AsyncCredentialsAuthenticator {
    func authenticate(credentials: User.Account.Login, for req: Request) async throws {
        guard let user = try await UserAccountModel
            .query(on: req.db)
            .filter(\.$email == credentials.email)
            .first()
        else {
            throw Abort(.unauthorized)
        }

        guard try req.application.password.verify(credentials.password, created: user.password) else {
            throw Abort(.unauthorized)
        }
        req.auth.login(user)
    }
}
