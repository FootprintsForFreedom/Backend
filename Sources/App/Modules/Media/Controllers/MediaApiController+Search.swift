import AppApi
import Fluent
import Vapor

extension MediaApiController: ApiElasticSearchController {
    // MARK: - Validators

    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }

    // MARK: - Routes

    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
        baseRoutes.get("suggest", use: suggestApi)
    }

    // MARK: - Search

    func searchQuery(_ searchContext: AppApi.DefaultSearchContext, _ pageRequest: Fluent.PageRequest, on elastic: ElasticHandler) async throws -> [String: Any] {
        let tags = try await TagApiController().search(searchContext, PageRequest(page: 1, per: 100), on: elastic)

        var shouldQueries: [[String: Any]] = [
            [
                "multi_match": [
                    "query": searchContext.text,
                    "fields": ["title", "detailText"],
                ],
            ],
        ]

        let tagTermQueries: [[String: Any]] = tags.items.map {
            [
                "term": [
                    "tags": [
                        "value": $0.id.uuidString,
                    ],
                ],
            ]
        }
        shouldQueries.append(contentsOf: tagTermQueries)

        let query: [String: Any] = [
            "from": (pageRequest.page - 1) * pageRequest.per,
            "size": pageRequest.per,
            "query": [
                "bool": [
                    "should": shouldQueries,
                ],
            ],
        ]

        return query
    }

    func searchOutput(_ req: Request, _ model: MediaSummaryModel.Elasticsearch) async throws -> Media.Detail.List {
        listOutput(req, model)
    }
}
