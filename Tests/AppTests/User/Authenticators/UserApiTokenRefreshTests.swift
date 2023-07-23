import Fluent
import Spec
import XCTVapor
import JWT
@testable import JWTKit
@testable import App

final class UserApiTokenRefreshTests: AppTestCase, UserTest {
    let refreshTokenPath = "/api/v1/token-refresh"

    func testSuccessfulTokenRefresh() async throws {
        let user = try await getUser(role: .user)
        let (refreshToken, signedRefreshToken) = try await getUnsignedAndSignedToken(type: .tokenRefresh, for: user)

        var accessTokenString: String!
        var newRefreshTokenString: String!

        // wait so the refresh token times are not too similar
        try await Task.sleep(for: .seconds(1))

        try app
            .describe("Refresh token should return new access and refresh token and invalidate the old refresh token")
            .post(refreshTokenPath)
            .bearerToken(signedRefreshToken)
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.user.id, user.id!)
                XCTAssertEqual(content.user.email, user.email)
                accessTokenString = content.accessToken
                newRefreshTokenString = content.refreshToken
            }
            .test()

        guard let accessTokenString, let newRefreshTokenString else {
            XCTFail("No tokens")
            return
        }

        // test signature
        XCTAssertNoThrow(try app.jwt.signers.verify(accessTokenString, as: UserToken.self))
        XCTAssertNoThrow(try app.jwt.signers.verify(newRefreshTokenString, as: UserToken.self))

        // test access token
        let accessTokenParser = try JWTParser(token: accessTokenString.bytes)
        let accessToken = try accessTokenParser.payload(as: UserToken.self, jsonDecoder: app.jwt.signers.defaultJSONDecoder)

        XCTAssertNoThrow(try accessToken.verify(intendedAudienceIncludes: .contentAccess))
        XCTAssertEqual(accessToken.userId, user.id!)
        XCTAssertEqual(accessToken.emailVerified, user.verified)
        XCTAssertEqual(accessToken.userRole, user.role)
        XCTAssertNil(accessToken.tokenFamily)

        // test new refresh token
        let refreshTokenParser = try JWTParser(token: newRefreshTokenString.bytes)
        let newRefreshToken = try refreshTokenParser.payload(as: UserToken.self, jsonDecoder: app.jwt.signers.defaultJSONDecoder)
        let refreshTokenFamily = try await UserTokenFamilyModel.find(newRefreshToken.tokenFamily, on: app.db)

        XCTAssertNoThrow(try newRefreshToken.verify(intendedAudienceIncludes: .tokenRefresh))
        XCTAssertNotNil(refreshTokenFamily)
        XCTAssertEqual(refreshToken.tokenFamily, newRefreshToken.tokenFamily)
        if let refreshTokenFamily {
            XCTAssertNoThrow(try newRefreshToken.verify(issuedAfter: refreshTokenFamily.lastTokenRefresh))
        }
        XCTAssertEqual(newRefreshToken.userId, user.id!)
        XCTAssertNil(newRefreshToken.emailVerified)
        XCTAssertNil(newRefreshToken.userRole)
        XCTAssertNotNil(newRefreshToken.tokenFamily)

        // test old refresh token invalid
        if let refreshTokenFamily {
            XCTAssertThrowsError(try refreshToken.verify(issuedAfter: refreshTokenFamily.lastTokenRefresh)) { error in
                XCTAssert(error is JWTError)
            }
        }
    }

    func testTokenRefreshWithAccessTokenFails() async throws {
        let token = try await getToken(for: .user)

        try app
            .describe("Access Token should not be usable to request new token")
            .post(refreshTokenPath)
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }

    func testTokenRefreshWithVerificationTokenFails() async throws {
        let token = try await getToken(type: .verification, for: .user)

        try app
            .describe("Verification token should not be usable to request new token")
            .post(refreshTokenPath)
            .bearerToken(token)
            .expect(.unauthorized)
            .test()
    }
}
