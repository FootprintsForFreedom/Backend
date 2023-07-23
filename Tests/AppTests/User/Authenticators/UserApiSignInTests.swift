import Fluent
import JWT
import Spec
import XCTVapor
@testable import App
@testable import JWTKit

final class UserApiSignInTests: AppTestCase, UserTest {
    let signInPath = "/api/v1/sign-in/"

    func testSuccessfulCredentialsLogin() async throws {
        let password = UUID().uuidString
        let user = try await createNewUser(password: password)

        let credentials = User.Account.Login(email: user.email, password: password)

        var accessTokenString: String!
        var refreshTokenString: String!

        try app
            .describe("Credentials login should return ok")
            .post(signInPath)
            .body(credentials)
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.user.id, user.id!)
                XCTAssertEqual(content.user.email, user.email)
                accessTokenString = content.accessToken
                refreshTokenString = content.refreshToken
            }
            .test()

        // test signature
        XCTAssertNoThrow(try app.jwt.signers.verify(accessTokenString, as: UserToken.self))
        XCTAssertNoThrow(try app.jwt.signers.verify(refreshTokenString, as: UserToken.self))

        // test access token
        let accessTokenParser = try JWTParser(token: accessTokenString.bytes)
        let accessToken = try accessTokenParser.payload(as: UserToken.self, jsonDecoder: app.jwt.signers.defaultJSONDecoder)

        XCTAssertNoThrow(try accessToken.verify(intendedAudienceIncludes: .contentAccess))
        XCTAssertEqual(accessToken.userId, user.id!)
        XCTAssertEqual(accessToken.emailVerified, user.verified)
        XCTAssertEqual(accessToken.userRole, user.role)
        XCTAssertNil(accessToken.tokenFamily)

        // test refresh token
        let refreshTokenParser = try JWTParser(token: refreshTokenString.bytes)
        let refreshToken = try refreshTokenParser.payload(as: UserToken.self, jsonDecoder: app.jwt.signers.defaultJSONDecoder)
        let refreshTokenFamily = try await UserTokenFamilyModel.find(refreshToken.tokenFamily, on: app.db)

        XCTAssertNoThrow(try refreshToken.verify(intendedAudienceIncludes: .tokenRefresh))
        XCTAssertNotNil(refreshTokenFamily)
        if let refreshTokenFamily {
            XCTAssertNoThrow(try refreshToken.verify(issuedAfter: refreshTokenFamily.lastTokenRefresh))
        }
        XCTAssertEqual(refreshToken.userId, user.id!)
        XCTAssertNil(refreshToken.emailVerified)
        XCTAssertNil(refreshToken.userRole)
        XCTAssertNotNil(refreshToken.tokenFamily)
    }

    func testSuccessfulBasicAuthLogin() async throws {
        let password = UUID().uuidString
        let user = try await createNewUser(password: password)

        let basicAuthString = "\(user.email):\(password)"
        let basicAuthBase64String = Data(basicAuthString.utf8).base64EncodedString()

        var accessTokenString: String!
        var refreshTokenString: String!

        try app
            .describe("Credentials login should return ok")
            .post(signInPath)
            .header("Authorization", "Basic \(basicAuthBase64String)")
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.user.id, user.id!)
                XCTAssertEqual(content.user.email, user.email)
                accessTokenString = content.accessToken
                refreshTokenString = content.refreshToken
            }
            .test()

        // test signature
        XCTAssertNoThrow(try app.jwt.signers.verify(accessTokenString, as: UserToken.self))
        XCTAssertNoThrow(try app.jwt.signers.verify(refreshTokenString, as: UserToken.self))

        // test access token
        let accessTokenParser = try JWTParser(token: accessTokenString.bytes)
        let accessToken = try accessTokenParser.payload(as: UserToken.self, jsonDecoder: app.jwt.signers.defaultJSONDecoder)

        XCTAssertNoThrow(try accessToken.verify(intendedAudienceIncludes: .contentAccess))
        XCTAssertEqual(accessToken.userId, user.id!)
        XCTAssertEqual(accessToken.emailVerified, user.verified)
        XCTAssertEqual(accessToken.userRole, user.role)
        XCTAssertNil(accessToken.tokenFamily)

        // test refresh token
        let refreshTokenParser = try JWTParser(token: refreshTokenString.bytes)
        let refreshToken = try refreshTokenParser.payload(as: UserToken.self, jsonDecoder: app.jwt.signers.defaultJSONDecoder)
        let refreshTokenFamily = try await UserTokenFamilyModel.find(refreshToken.tokenFamily, on: app.db)

        XCTAssertNoThrow(try refreshToken.verify(intendedAudienceIncludes: .tokenRefresh))
        XCTAssertNotNil(refreshTokenFamily)
        if let refreshTokenFamily {
            XCTAssertNoThrow(try refreshToken.verify(issuedAfter: refreshTokenFamily.lastTokenRefresh))
        }
        XCTAssertEqual(refreshToken.userId, user.id!)
        XCTAssertNil(refreshToken.emailVerified)
        XCTAssertNil(refreshToken.userRole)
        XCTAssertNotNil(refreshToken.tokenFamily)
    }

    func testLoginWithNonExistingUserFails() throws {
        let credentials = User.Account.Login(email: "thisemail.doesntexist@example.com", password: "123")

        try app
            .describe("Credentials Login with non existing user should fail")
            .post(signInPath)
            .body(credentials)
            .expect(.unauthorized)
            .test()
    }

    func testLoginWithIncorrectPasswordFails() async throws {
        let user = try await getUser(role: .user)

        let credentials = User.Account.Login(email: user.email, password: "wrongPassword")

        try app
            .describe("Credentials Login should return ok")
            .post(signInPath)
            .body(credentials)
            .expect(.unauthorized)
            .test()
    }
}
