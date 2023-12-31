import AppApi
import ElasticsearchNIOClient
import Fluent
import Vapor

protocol ElasticSearchController: ElasticModelController {
    /// The elasticsearch search query to be used.
    /// - Returns: A json formatted array.
    /// - Parameters:
    ///   - searchContext: The search terms submitted by the user.
    ///   - elastic: An elastic handler to perform optional previous queries.
    func searchQuery(_ searchContext: AppApi.DefaultSearchContext, _ pageRequest: Fluent.PageRequest, on elastic: ElasticHandler) async throws -> [String: Any]

    /// Searches elasticsearch to get a page of elastic models.
    /// - Parameters:
    ///   - searchQuery: The search query to use for search.
    ///   - pageRequest: The page request to paginate the results.
    ///   - elastic: The elastic handler to perform the search.
    /// - Returns: A page of elastic models.
    func search(_ searchContext: AppApi.DefaultSearchContext, _ pageRequest: Fluent.PageRequest, on elastic: ElasticHandler) async throws -> AppApi.Page<ElasticModel>

    /// The elasticsearch suggest query to be used.
    /// - Returns: A json formatted array.
    /// - Parameters:
    ///   - searchContext: The search terms submitted by the user.
    ///   - elastic: An elastic handler to perform optional previous queries.
    func suggestQuery(_ searchContext: AppApi.DefaultSearchContext, on elastic: ElasticHandler) async throws -> [String: Any]

    /// Searches elasticsearch to get search suggestions..
    /// - Parameters:
    ///   - searchQuery: The search query to use for search.
    ///   - elastic: The elastic handler to perform the search.
    /// - Returns: A  list of elastic model suggestions..
    func suggest(_ searchContext: AppApi.DefaultSearchContext, on elastic: ElasticHandler) async throws -> [ElasticModel]
}

extension ElasticSearchController {
    func search(_ searchContext: AppApi.DefaultSearchContext, _ pageRequest: Fluent.PageRequest, on elastic: ElasticHandler) async throws -> AppApi.Page<ElasticModel> {
        let query = try await searchQuery(searchContext, pageRequest, on: elastic)

        return try await elastic.perform {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await elastic.custom("/\(ElasticModel.schema(for: searchContext.languageCode))/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData)

            return Page(
                items: response.hits.hits.map(\.source),
                metadata: PageMetadata(page: pageRequest.page, per: pageRequest.per, total: response.hits.total.value)
            )
        }
    }

    func suggestQuery(_ searchContext: AppApi.DefaultSearchContext, on elastic: ElasticHandler) async throws -> [String: Any] {
        [
            "suggest": [
                "completion": [
                    "prefix": searchContext.text,
                    "completion": [
                        "field": "title.suggest",
                        "size": 15,
                        "skip_duplicates": true,
                    ],
                ],
            ],
        ]
    }

    func suggest(_ searchContext: AppApi.DefaultSearchContext, on elastic: ElasticHandler) async throws -> [ElasticModel] {
        let query = try await suggestQuery(searchContext, on: elastic)
        return try await elastic.perform {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await elastic.custom("/\(ElasticModel.schema(for: searchContext.languageCode))/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESSuggestDocumentsResponse<ElasticModel>.self, from: responseData)
            let suggest = try response.suggestFor("completion")

            return suggest.options.map(\.source)
        }
    }
}
