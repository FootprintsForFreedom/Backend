import Vapor

struct TagRouter: RouteCollection {
    let apiController = TagApiController()
    let waypointApiController = WaypointApiController()
    let mediaApiController = MediaApiController()

    func boot(routes: RoutesBuilder) throws { }

    func apiRoutesHook(_ args: HookArguments) {
        let routes = args[.routes] as! RoutesBuilder

        apiController.setupRoutes(routes)
        apiController.setupSearchRoutes(routes)
        apiController.setupVerificationRoutes(routes)
        apiController.setupReportRoutes(routes)
        apiController.setupWaypointRoutes(routes)
        apiController.setupMediaRoutes(routes)
        waypointApiController.setupTagRoutes(routes)
        mediaApiController.setupTagRoutes(routes)
    }
}
