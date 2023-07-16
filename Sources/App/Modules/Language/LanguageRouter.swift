import Vapor

struct LanguageRouter: RouteCollection {
    let apiController = LanguageApiController()

    func boot(routes: RoutesBuilder) throws { }

    func apiRoutesHook(_ args: HookArguments) {
        let routes = args["routes"] as! RoutesBuilder

        apiController.setupRoutes(routes)
        apiController.setupPriorityRoutes(routes)
    }
}
