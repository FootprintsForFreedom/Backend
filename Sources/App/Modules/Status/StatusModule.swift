import Vapor

struct StatusModule: ModuleInterface {
    func boot(_ app: Application) throws {
        app.migrations.add(StatusMigrations.v1())
    }
}
