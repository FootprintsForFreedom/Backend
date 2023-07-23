@_exported import AppApi
import FluentPostgresDriver
import XCTVapor
@testable import App

extension Environment {
    static let pgTestDbName = Self.get("POSTGRES_TEST_DB") ?? pgDbName
}

enum AppTestCaseError: Error {
    case appNotFound
}

open class AppTestCase: XCTestCase {
    var app: Application!
    var moderatorToken: String!

    func createTestApp() async throws -> Application {
        let app = Application(.testing)

        try await configure(app)
        app.databases.reinitialize()
        app.databases.use(
            .postgres(configuration: SQLPostgresConfiguration(
                hostname: Environment.dbHost,
                port: Environment.dbPort.flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.pgUser,
                password: Environment.pgPassword,
                database: Environment.pgTestDbName,
                tls: .disable
            )),
            as: .psql
        )
        app.databases.default(to: .psql)
        app.passwords.use(.plaintext)
        try await app.autoMigrate()
        return app
    }

    override open func setUp() async throws {
        app = try await createTestApp()
        moderatorToken = try await getToken(for: .moderator)
    }

    override open func tearDown() async throws {
        guard let app else { throw AppTestCaseError.appNotFound }
        let waypointCount = try await WaypointDetailModel.query(on: app.db).count()
        let languageCount = try await LanguageModel.query(on: app.db).count()
        if waypointCount > 50 || languageCount > 100 {
            try await app.autoRevert()
        }
        app.shutdown()
    }

    func getUser(role: User.Role, verified: Bool = false) async throws -> UserAccountModel {
        let newUserPassword = "password"
        let newUser = try UserAccountModel(name: "Test User", email: "test-user\(UUID())@example.com", school: nil, password: app.password.hash(newUserPassword), verified: verified, role: role)
        try await newUser.create(on: app.db)
        return newUser
    }

    func getUnsignedAndSignedToken(type tokenType: UserTokenType = .contentAccess, for user: UserAccountModel) async throws -> (unsignedToken: UserToken, signedToken: String) {
        let token: UserToken!
        switch tokenType {
        case .contentAccess: token = try UserToken.createAccessToken(for: user)
        case .tokenRefresh: token = try await UserToken.createRefreshToken(for: user, on: app.db)
        case .verification: token = try await UserToken.createVerificationToken(for: user, on: app.db)
        }
        let signedToken = try app.jwt.signers.sign(token, kid: .private)
        return (token, signedToken)
    }

    func getToken(type tokenType: UserTokenType = .contentAccess, for user: UserAccountModel) async throws -> String {
        try await getUnsignedAndSignedToken(type: tokenType, for: user).signedToken
    }

    func getUnsignedAndSignedToken(type tokenType: UserTokenType = .contentAccess, for userRole: User.Role, verified: Bool = false) async throws -> (unsignedToken: UserToken, signedToken: String) {
        let newUser = try await getUser(role: userRole, verified: verified)
        return try await getUnsignedAndSignedToken(type: tokenType, for: newUser)
    }

    func getToken(type tokenType: UserTokenType = .contentAccess, for userRole: User.Role, verified: Bool = false) async throws -> String {
        try await getUnsignedAndSignedToken(type: tokenType, for: userRole, verified: verified).signedToken
    }
}
