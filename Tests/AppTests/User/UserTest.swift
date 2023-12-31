import Fluent
import XCTVapor
@testable import App

protocol UserTest: AppTestCase { }

extension UserTest {
    var usersPath: String { "api/v1/\(User.pathKey)/\(User.Account.pathKey)/" }

    func createNewUser(
        name: String = "New Test User \(UUID())",
        email: String = "test-user\(UUID())@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> UserAccountModel {
        let user = try UserAccountModel(name: name, email: email, school: school, password: app.password.hash(password), verified: verified, role: role)
        try await user.create(on: app.db)
        return user
    }

    func createNewUserWithToken(
        name: String = "New Test User \(UUID())",
        email: String = "test-user\(UUID())@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> (user: UserAccountModel, token: String) {
        let user = try await createNewUser(name: name, email: email, school: school, password: password, verified: verified, role: role)
        let token = try await getToken(for: user)

        return (user, token)
    }
}
