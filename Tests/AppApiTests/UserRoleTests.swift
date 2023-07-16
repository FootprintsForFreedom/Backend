import XCTest
@testable import AppApi

final class UserRoleTests: XCTestCase {
    func testRoleHierachy() {
        XCTAssertGreaterThan(User.Role.moderator, User.Role.user)
        XCTAssertGreaterThan(User.Role.admin, User.Role.moderator)
        XCTAssertGreaterThan(User.Role.superAdmin, User.Role.admin)
    }
}
