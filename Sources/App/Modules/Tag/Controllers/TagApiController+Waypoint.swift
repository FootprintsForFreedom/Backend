import AppApi
import ElasticsearchNIOClient
import Vapor

extension TagApiController {
    // MARK: - Routes

    func setupWaypointRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get("waypoints", use: listWaypoints)
    }

    // MARK: - List tag waypoint

    func listWaypoints(_ req: Request) async throws -> AppApi.Page<Waypoint.Detail.List> {
        typealias ElasticModel = WaypointSummaryModel.Elasticsearch

        let tagId = try identifier(req)
        let pageRequest = try req.pageRequest

        var query: [String: Any] = [
            "from": (pageRequest.page - 1) * pageRequest.per,
            "size": pageRequest.per,
            "query": [
                "term": [
                    "tags": tagId.uuidString,
                ],
            ],
            "collapse": [
                "field": "id",
            ],
            "aggs": [
                "count": [
                    "cardinality": [
                        "field": "id",
                    ],
                ],
            ],
        ]

        var sort: [[String: Any]] = []
        if let preferredLanguageCode = try req.preferredLanguageCode() {
            sort.append(
                [
                    "_script": [
                        "type": "number",
                        "script": [
                            "lang": "painless",
                            "source": "doc['languageCode'].value == params.preferredLanguageCode ? 0 : doc['languagePriority'].value",
                            "params": [
                                "preferredLanguageCode": "\(preferredLanguageCode)",
                            ],
                        ],
                        "order": "asc",
                    ],
                ]
            )
        } else {
            sort.append(["languagePriority": "asc"])
        }
        sort.append(["title.keyword": "asc"])
        query["sort"] = sort

        return try await req.elastic.perform {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await req.elastic.custom("/\(ElasticModel.wildcardSchema)/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData)
            guard
                let responseJson = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                let aggregations = responseJson["aggregations"] as? [String: Any],
                let countAggregation = aggregations["count"] as? [String: Any],
                let count = countAggregation["value"] as? Int
            else {
                throw Abort(.internalServerError)
            }

            let items = response.hits.hits.map {
                let source = $0.source
                return Waypoint.Detail.List(
                    id: source.id,
                    title: source.title,
                    slug: source.slug,
                    detailText: source.detailText,
                    location: .init(latitude: source.location.lat, longitude: source.location.lon),
                    languageCode: source.languageCode
                )
            }

            return Page(
                items: items,
                metadata: PageMetadata(page: pageRequest.page, per: pageRequest.per, total: count)
            )
        }
    }
}
