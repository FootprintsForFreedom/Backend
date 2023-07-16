import Vapor

struct StaticContentRouter: RouteCollection {
    let apiController = StaticContentApiController()

    func boot(routes: RoutesBuilder) throws { }

    func apiRoutesHook(_ args: HookArguments) {
        let routes = args["routes"] as! RoutesBuilder

        apiController.setupRoutes(routes)
    }
}
