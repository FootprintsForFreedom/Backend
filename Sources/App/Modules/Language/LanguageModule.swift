import Vapor

struct LanguageModule: ModuleInterface {
    let router = LanguageRouter()

    func boot(_ app: Application) throws {
        app.migrations.add(LanguageMigrations.v1())
        try app.migrations.add(LanguageMigrations.seed(elastic: app.elastic))

        app.hooks.register(.apiRoutesV1, use: router.apiRoutesHook)

        try router.boot(routes: app.routes)
    }
}
