import Fluent
import Spec
import XCTVapor
@testable import App

final class UserApiGetOwnUserTests: AppTestCase, UserTest {
    func testGetOwnUser() async throws {
        let user = try await getUser(role: .user)
        let token = try await getToken(for: user)

        try app
            .describe("Get own user should return authenticated user")
            .get(usersPath.appending("me"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id!)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
            }
            .test()
    }
}
