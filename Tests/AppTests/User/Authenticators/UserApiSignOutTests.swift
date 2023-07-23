import Fluent
import Spec
import XCTVapor
@testable import App

final class UserApiSignOutTests: AppTestCase {
    let signOutPath = "/api/v1/sign-out/"

    func testSuccessfulSignOut() async throws {
        let (token, signedToken) = try await getUnsignedAndSignedToken(type: .tokenRefresh, for: .user)

        try app
            .describe("When user signs out the token he used should be deleted")
            .post(signOutPath)
            .bearerToken(signedToken)
            .expect(.ok)
            .test()

        let tokenFamily = try await UserTokenFamilyModel.find(token.tokenFamily, on: app.db)
        XCTAssertNil(tokenFamily)
    }

    func testSuccessfulSignOutOnlyDeletesCurrentTokenFamily() async throws {
        let user = try await getUser(role: .user)
        let _ = try await getToken(type: .tokenRefresh, for: user)
        let initialTokenFamilyCount = try await user.$tokenFamilies.query(on: app.db).count()
        XCTAssertGreaterThan(initialTokenFamilyCount, 0)

        let token = try await getToken(type: .tokenRefresh, for: user)

        try app
            .describe("When user signs out the token he used should be deleted")
            .post(signOutPath)
            .bearerToken(token)
            .expect(.ok)
            .test()

        let numberOfTokenFamilies = try await user.$tokenFamilies.query(on: app.db).count()
        XCTAssertEqual(numberOfTokenFamilies, initialTokenFamilyCount)
    }

    func testSuccessfulSignOutAllDeletesAllTokenFamilies() async throws {
        let user = try await getUser(role: .user)
        let _ = try await getToken(type: .tokenRefresh, for: user)
        let initialTokenFamilyCount = try await user.$tokenFamilies.query(on: app.db).count()
        XCTAssertGreaterThan(initialTokenFamilyCount, 0)

        let token = try await getToken(type: .tokenRefresh, for: user)

        try app
            .describe("When user signs out of all sessions all token he used should be deleted")
            .post(signOutPath.appending("?all=true"))
            .bearerToken(token)
            .expect(.ok)
            .test()

        let numberOfTokenFamilies = try await user.$tokenFamilies.query(on: app.db).count()
        XCTAssertEqual(numberOfTokenFamilies, 0)
    }

    func testSignOutWithAccessTokenFails() async throws {
        let token = try await getToken(for: .user)

        try app
            .describe("The user should not be able to sign out with an access token")
            .post(signOutPath)
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }

    func testSignOutWithVerificationTokenFails() async throws {
        let token = try await getToken(type: .verification, for: .user)

        try app
            .describe("The user should not be able to sign out with an identity verification token")
            .post(signOutPath)
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }
}
