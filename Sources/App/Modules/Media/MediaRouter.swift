import Vapor

struct MediaRouter: RouteCollection {
    let apiController = MediaApiController()
    let waypointApiController = WaypointApiController()

    func boot(routes: RoutesBuilder) throws { }

    func apiRoutesHook(_ args: HookArguments) {
        let routes = args["routes"] as! RoutesBuilder

        apiController.setupRoutes(routes)
        apiController.setupSearchRoutes(routes)
        apiController.setupVerificationRoutes(routes)
        apiController.setupReportRoutes(routes)
        waypointApiController.setupMediaRoute(routes)
    }
}
