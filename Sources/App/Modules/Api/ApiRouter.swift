import Vapor

struct ApiRouter: RouteCollection {
    func boot(routes: RoutesBuilder) throws { }

    func setUpRoutesHooks(app: Application) throws {
        let apiRoutes = app.routes
            .grouped("api")
            .grouped("v1")

        let accessTokenMiddlewareApiRoutes = apiRoutes
            .grouped(UserJWTAccessTokenAuthenticator())

        let _: [Void] = app.invokeAll(.apiRoutesV1, args: [.routes: accessTokenMiddlewareApiRoutes, .routesWithoutAccessTokenMiddleware: apiRoutes])
        let _: [Void] = app.invokeAll(.apiRedirects, args: [.routes: app.routes])
    }
}
