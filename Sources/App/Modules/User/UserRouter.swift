import Vapor

struct UserRouter: RouteCollection {
    let apiController = UserApiController()

    func boot(routes: RoutesBuilder) throws { }

    func apiRoutesHook(_ args: HookArguments) {
        let routes = args[.routes] as! RoutesBuilder
        let routesWithoutAccessTokenMiddleware = args[.routesWithoutAccessTokenMiddleware] as! RoutesBuilder

        apiController.setupRoutes(routes)
        apiController.setupAuthRoutes(routesWithoutAccessTokenMiddleware)
        apiController.setupDetailOwnUserRoutes(routes)
        apiController.setupUpdatePasswordRoutes(routes)
        apiController.setupVerificationRoutes(routesWithoutAccessTokenMiddleware)
        apiController.setupResetPasswordRoutes(routesWithoutAccessTokenMiddleware)
        apiController.setupChangeRoleRoutes(routes)
    }
}
