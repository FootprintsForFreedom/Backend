import Vapor

struct RedirectModule: ModuleInterface {
    let router = RedirectRouter()

    func boot(_ app: Application) throws {
        app.migrations.add(RedirectMigrations.v1())
        app.hooks.register(.apiRoutesV1, use: router.apiRoutesHook)
        app.hooks.register(.apiRedirects, use: router.redirectHook)

        try router.boot(routes: app.routes)
    }
}
