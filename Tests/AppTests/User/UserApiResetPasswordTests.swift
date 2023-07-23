import Fluent
import Spec
import XCTVapor
@testable import App

extension User.Account.ResetPasswordRequest: Content { }
extension User.Account.ResetPassword: Content { }

final class UserApiResetPasswordTests: AppTestCase, UserTest {
    // MARK: - request reset password

    private func resetPasswordRequest(for user: UserAccountModel) -> User.Account.ResetPasswordRequest {
        User.Account.ResetPasswordRequest(email: user.email)
    }

    func testSuccessfulRequestResetPassword() async throws {
        let user = try await createNewUser()
        let resetPasswordRequest = resetPasswordRequest(for: user)

        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest)
            .expect(.ok)
            .test()
    }

    func testRequestResetPasswordDeletesOldTokens() async throws {
        let user = try await createNewUser()
        let resetPasswordRequest = resetPasswordRequest(for: user)

        // Get original verification token count
        let verificationTokenCount1 = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()

        let _ = try await getToken(type: .verification, for: user)

        let verificationTokenCount2 = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()
        XCTAssertEqual(verificationTokenCount2, verificationTokenCount1 + 1)

        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest)
            .expect(.ok)
            .test()

        let verificationTokenCount3 = try await user.$tokenFamilies.query(on: app.db).filter(\.$tokenType, .equal, .verification).count()
        XCTAssertEqual(verificationTokenCount3, verificationTokenCount1 + 1)
    }

    func testRequestResetPasswordWithWrongEmailFails() async throws {
        let resetPasswordRequest1 = User.Account.ResetPasswordRequest(email: "")
        let resetPasswordRequest2 = User.Account.ResetPasswordRequest(email: "test@test")
        let resetPasswordRequest3 = User.Account.ResetPasswordRequest(email: "@test.com")
        let resetPasswordRequest4 = User.Account.ResetPasswordRequest(email: "test.com")

        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest1)
            .expect(.badRequest)
            .test()

        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest2)
            .expect(.badRequest)
            .test()

        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest3)
            .expect(.badRequest)
            .test()

        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest4)
            .expect(.badRequest)
            .test()
    }

    // MARK: - reset password

    private func resetPasswordContent(for user: UserAccountModel, with newPassword: String) async throws -> User.Account.ResetPassword {
        User.Account.ResetPassword(newPassword: newPassword)
    }

    func testSuccessfulResetPassword() async throws {
        let password = "password7293"
        let user = try await createNewUser(password: password)
        let newPassword = "my3NewPassword"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        let verificationToken = try await getToken(type: .verification, for: user)

        try app
            .describe("User should successfully reset password")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
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

        // test user can sign in with new password
        let signInPath = "/api/v1/sign-in/"
        let credentials = User.Account.Login(email: user.email, password: newPassword)

        try app
            .describe("Credentials login should return ok with new password")
            .post(signInPath)
            .body(credentials)
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.user.id, user.id!)
                XCTAssertEqual(content.user.email, user.email)
            }
            .test()

        // test user cannot sign in with old password
        let oldCredentials = User.Account.Login(email: user.email, password: password)

        try app
            .describe("Credentials login should fail with old password")
            .post(signInPath)
            .body(oldCredentials)
            .expect(.unauthorized)
            .test()
    }

    func testNewPasswordNeedsAtLeastSixCharacters() async throws {
        let user = try await createNewUser()
        let newPassword = "1aB"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        let verificationToken = try await getToken(type: .verification, for: user)

        try app
            .describe("New user password needs at least six characters; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(verificationToken)
            .expect(.badRequest)
            .test()
    }

    func testNewPasswordNeedsUppercasedLetter() async throws {
        let user = try await createNewUser()
        let newPassword = "alllowwercase34"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        let verificationToken = try await getToken(type: .verification, for: user)

        try app
            .describe("New user password needs at least one uppercased letter; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(verificationToken)
            .expect(.badRequest)
            .test()
    }

    func testNewPasswordNeedsLowercasedLetter() async throws {
        let user = try await createNewUser()
        let newPassword = "1NEWPASSWORD"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        let verificationToken = try await getToken(type: .verification, for: user)

        try app
            .describe("New user password needs at least one lowercased letter; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(verificationToken)
            .expect(.badRequest)
            .test()
    }

    func testNewPasswordNeedsDigit() async throws {
        let user = try await createNewUser()
        let newPassword = "myNewPassword"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        let verificationToken = try await getToken(type: .verification, for: user)

        try app
            .describe("New user password needs at least one digit; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(verificationToken)
            .expect(.badRequest)
            .test()
    }

    func testNewPasswordWihtNewLineFails() async throws {
        let user = try await createNewUser()
        let newPassword = "my3New\nPassword"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        let verificationToken = try await getToken(type: .verification, for: user)

        try app
            .describe("New user password must not contain new line; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(verificationToken)
            .expect(.badRequest)
            .test()
    }

    func testResetPasswordWithOldVerificationTokenFails() async throws {
        let user = try await getUser(role: .user)
        XCTAssertFalse(user.verified)
        let oldVerificationToken = try await getToken(type: .verification, for: user)

        let newPassword = "my3NewPassword"
        let resetPasswordContent = User.Account.ResetPassword(newPassword: newPassword)

        try await Task.sleep(for: .seconds(1))
        let _ = try await user.createSignedVerificationToken(on: Request(application: app, on: app.eventLoopGroup.next()))

        try app
            .describe("User should not be verified")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(oldVerificationToken)
            .expect(.unauthorized)
            .test()
    }

    func testResetPasswordWithTokenFromOtherUserFails() async throws {
        let user = try await getUser(role: .user)
        XCTAssertFalse(user.verified)
        let _ = try await getToken(type: .verification, for: user)
        let otherUser = try await getUser(role: .user)
        XCTAssertFalse(otherUser.verified)
        let wrongVerificationToken = try await getToken(type: .verification, for: otherUser)

        let newPassword = "my3NewPassword"
        let resetPasswordContent = User.Account.ResetPassword(newPassword: newPassword)

        try app
            .describe("User should not be verified")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .bearerToken(wrongVerificationToken)
            .body(resetPasswordContent)
            .expect(.unauthorized)
            .test()
    }

    func testPasswordResetWithAccessTokenFails() async throws {
        let user = try await getUser(role: .user)
        let token = try await getToken(for: user)

        let newPassword = "my3NewPassword"
        let resetPasswordContent = User.Account.ResetPassword(newPassword: newPassword)

        try app
            .describe("Access Token should not be usable to request new token")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }

    func testPasswordResetWithRefreshTokenFails() async throws {
        let user = try await getUser(role: .user)
        let token = try await getToken(type: .tokenRefresh, for: user)

        let newPassword = "my3NewPassword"
        let resetPasswordContent = User.Account.ResetPassword(newPassword: newPassword)

        try app
            .describe("Verification token should not be usable to request new token")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }
}
