import AppApi
import Fluent
import Vapor

protocol ApiElasticSearchController: ElasticSearchController {
    /// The search object content.
    associatedtype ListObject: Content

    /// The ``AsyncValidator``s which need to be fulfilled before searching a model.
    /// - Returns: The ``AsyncValidator``s which need to be fulfilled before searching a model.
    func searchValidators() -> [AsyncValidator]

    /// The detail output for a page of repositories.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repositories: The repositories to be in the output.
    /// - Returns: A paged search of search objects.
    func searchOutput(_ req: Request, _ models: AppApi.Page<ElasticModel>) async throws -> AppApi.Page<ListObject>

    /// The detail output for one repository.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repository: The repository to be in the output.
    /// - Returns: A search object of the repository and detail.
    func searchOutput(_ req: Request, _ model: ElasticModel) async throws -> ListObject

    /// The search repositories api action.
    /// - Parameter req: The request on which to search the repositories.
    /// - Returns: A paged search of the repositories.
    func searchApi(_ req: Request) async throws -> AppApi.Page<ListObject>

    /// The suggest repositories api action.
    ///
    /// A suggester provides auto-complete/search-as-you-type functionality. This is a navigational feature to guide users to relevant results as they are typing, improving search precision.
    /// - Parameter req: The request on which to suggest the repositories
    /// - Returns: A list of the suggested repositories
    func suggestApi(_ req: Request) async throws -> [ListObject]

    /// Sets up the search repository routes.
    /// - Parameter routes: The routes on which to setup the search repository routes.
    func setupSearchRoutes(_ routes: RoutesBuilder)
}

extension ApiElasticSearchController {
    func searchValidators() -> [AsyncValidator] {
        []
    }

    func searchApi(_ req: Request) async throws -> AppApi.Page<ListObject> {
        try await RequestValidator(searchValidators()).validate(req, .query)
        let searchContext = try req.query.decode(AppApi.DefaultSearchContext.self)

        guard searchContext.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            throw Abort(.badRequest)
        }

        let pageRequest = try req.pageRequest

        let models = try await search(searchContext, pageRequest, on: req.elastic)
        return try await searchOutput(req, models)
    }

    func suggestApi(_ req: Request) async throws -> [ListObject] {
        try await RequestValidator(searchValidators()).validate(req, .query)
        let searchContext = try req.query.decode(AppApi.DefaultSearchContext.self)

        guard searchContext.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            throw Abort(.badRequest)
        }

        let models = try await suggest(searchContext, on: req.elastic)
        return try await models.concurrentCompactMap { try await searchOutput(req, $0) }
    }

    func searchOutput(_ req: Request, _ models: AppApi.Page<ElasticModel>) async throws -> AppApi.Page<ListObject> {
        try await models.concurrentCompactMap { model in
            try await searchOutput(req, model)
        }
    }

    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
        baseRoutes.get("suggest", use: suggestApi)
    }
}
