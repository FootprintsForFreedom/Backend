import FluentPostgresDriver
import XCTVapor
@testable import App

final class MigrationTests: XCTestCase {
    func testMigrateAndTearDown() async throws {
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
        try await app.autoRevert()
        app.shutdown()
    }
}
