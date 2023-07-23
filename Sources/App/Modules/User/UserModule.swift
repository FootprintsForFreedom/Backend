import Vapor

struct UserModule: ModuleInterface {
    let router = UserRouter()

    func boot(_ app: Application) throws {
        app.migrations.add(UserMigrations.v1())
        app.migrations.add(UserMigrations.seed())

        app.hooks.register(.apiRoutesV1, use: router.apiRoutesHook)

        try router.boot(routes: app.routes)
    }
}
