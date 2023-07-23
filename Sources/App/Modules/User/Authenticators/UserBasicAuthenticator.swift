import Fluent
import Vapor

struct UserBasicAuthenticator: AsyncBasicAuthenticator {
    func authenticate(basic: BasicAuthorization, for req: Request) async throws {
        guard let user = try await UserAccountModel
            .query(on: req.db)
            .filter(\.$email == basic.username)
            .first()
        else {
            throw Abort(.unauthorized)
        }

        guard try req.application.password.verify(basic.password, created: user.password) else {
            throw Abort(.unauthorized)
        }
        req.auth.login(user)
    }
}
