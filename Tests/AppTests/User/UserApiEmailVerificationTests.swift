import Fluent
import Spec
import XCTVapor
@testable import App

final class UserApiEmailVerificationTests: AppTestCase, UserTest {
    // MARK: - request verification

    func testSuccessfulRequestVerification() async throws {
        let (user, token) = try await createNewUserWithToken()
        XCTAssertFalse(user.verified)

        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.ok)
            .test()
    }

    func testRequestVerificationDeletesOldTokens() async throws {
        let (user, token) = try await createNewUserWithToken()
        XCTAssertFalse(user.verified)

        // Get original verification token count
        let verificationTokenCount1 = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()

        let _ = try await getToken(type: .verification, for: user)

        let verificationTokenCount2 = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()
        XCTAssertEqual(verificationTokenCount2, verificationTokenCount1 + 1)

        try app
            .describe("User should successfully request verification and thereby delete old verification tokens")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.ok)
            .test()

        let verificationTokenCount3 = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()
        XCTAssertEqual(verificationTokenCount3, verificationTokenCount1 + 1)
    }

    func testRequestVerificationFromDifferentUserFails() async throws {
        let user = try await getUser(role: .user)
        XCTAssertFalse(user.verified)

        let token = try await getToken(for: .user)
        let moderatorToken = try await getToken(for: .moderator)

        try app
            .describe("Different user should not be able to request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()

        try app
            .describe("Different admin user should not be able to request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .test()
    }

    func testRequestVerificationFromVerifiedUserFails() async throws {
        let (user, token) = try await createNewUserWithToken(verified: true)
        XCTAssertTrue(user.verified)

        try app
            .describe("Verified user should not be able to request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }

    func testRequestVerificationWithoutTokenFails() async throws {
        let user = try await createNewUser()
        XCTAssertFalse(user.verified)

        try app
            .describe("Request verification without bearer token fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .expect(.unauthorized)
            .test()
    }

    // MARK: - verification

    func testSuccessfulUserVerification() async throws {
        let user = try await getUser(role: .user)
        XCTAssertFalse(user.verified)

        // Get original verification token count
        let initialVerificationTokenCount = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()
        XCTAssertEqual(initialVerificationTokenCount, 0)

        let verificationToken = try await getToken(type: .verification, for: user)

        try app
            .describe("User should be verified successfully and get own detail content")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify")))
            .bearerToken(verificationToken)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertNil(content.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertNil(content.verified)
                XCTAssertNil(content.role)
                Task {
                    guard let user = try await UserAccountModel.find(user.id, on: self.app.db) else {
                        XCTFail()
                        return
                    }
                    // User is verified after password reset since he has access to his email
                    XCTAssertEqual(user.verified, true)
                }
            }
            .test()

        // check token is deleted after verification
        let verificationTokenCount = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()
        XCTAssertEqual(verificationTokenCount, 0)
    }

    func testVerificationWithOldVerificationTokenFails() async throws {
        let user = try await getUser(role: .user)
        XCTAssertFalse(user.verified)
        let oldVerificationToken = try await getToken(type: .verification, for: user)
        try await Task.sleep(for: .seconds(1))
        let _ = try await user.createSignedVerificationToken(on: Request(application: app, on: app.eventLoopGroup.next()))

        try app
            .describe("User should not be verified")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify")))
            .bearerToken(oldVerificationToken)
            .expect(.unauthorized)
            .test()
    }

    func testVerificationWithTokenFromOtherUserFails() async throws {
        let user = try await getUser(role: .user)
        XCTAssertFalse(user.verified)
        let _ = try await getToken(type: .verification, for: user)
        let otherUser = try await getUser(role: .user)
        XCTAssertFalse(otherUser.verified)
        let wrongVerificationToken = try await getToken(type: .verification, for: otherUser)

        try app
            .describe("User should not be verified")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify")))
            .bearerToken(wrongVerificationToken)
            .expect(.unauthorized)
            .test()
    }

    func testVerificationWithAccessTokenFails() async throws {
        let user = try await getUser(role: .user)
        let token = try await getToken(for: user)

        try app
            .describe("Access Token should not be usable to request new token")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify")))
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }

    func testVerificationWithRefreshTokenFails() async throws {
        let user = try await getUser(role: .user)
        let token = try await getToken(type: .tokenRefresh, for: user)

        try app
            .describe("Verification token should not be usable to request new token")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify")))
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }
}
