import AppApi
import ElasticsearchNIOClient
import Fluent
import Vapor

final class WaypointSummaryModel: DatabaseElasticInterface {
    typealias Module = WaypointModule

    static var schema: String = "waypoint_summaries"

    enum FieldKeys {
        enum v1 {
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var detailText: FieldKey { "detail_text" }
            static var detailUserId: FieldKey { "detail_user_id" }
            static var detailVerifiedAt: FieldKey { "detail_verified_at" }
            static var detailCreatedAt: FieldKey { "detail_created_at" }
            static var detailUpdatedAt: FieldKey { "detail_updated_at" }
            static var detailDeletedAt: FieldKey { "detail_deleted_at" }
            static var detailId: FieldKey { "detail_id" }
            static var latitude: FieldKey { "latitude" }
            static var longitude: FieldKey { "longitude" }
            static var locationUserId: FieldKey { "location_user_id" }
            static var locationVerifiedAt: FieldKey { "location_verified_at" }
            static var locationCreatedAt: FieldKey { "location_created_at" }
            static var locationUpdatedAt: FieldKey { "location_updated_at" }
            static var locationDeletedAt: FieldKey { "location_deleted_at" }
            static var locationId: FieldKey { "location_id" }
            static var languageCode: FieldKey { "language_code" }
            static var languageName: FieldKey { "language_name" }
            static var languageIsRTL: FieldKey { "language_is_rtl" }
            static var languagePriority: FieldKey { "language_priority" }
            static var languageId: FieldKey { "language_id" }
        }
    }

    @ID() var id: UUID?

    @Field(key: FieldKeys.v1.detailId) var detailId: UUID
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.detailText) var detailText: String
    @OptionalField(key: FieldKeys.v1.detailUserId) var detailUserId: UUID?
    @OptionalField(key: FieldKeys.v1.detailVerifiedAt) var detailVerifiedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailCreatedAt) var detailCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailUpdatedAt) var detailUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailDeletedAt) var detailDeletedAt: Date?

    @Field(key: FieldKeys.v1.locationId) var locationId: UUID
    @Field(key: FieldKeys.v1.latitude) var latitude: Double
    @Field(key: FieldKeys.v1.longitude) var longitude: Double
    @OptionalField(key: FieldKeys.v1.locationUserId) var locationUserId: UUID?
    @OptionalField(key: FieldKeys.v1.locationVerifiedAt) var locationVerifiedAt: Date?
    @OptionalField(key: FieldKeys.v1.locationCreatedAt) var locationCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.locationUpdatedAt) var locationUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.locationDeletedAt) var locationDeletedAt: Date?

    @Field(key: FieldKeys.v1.languageId) var languageId: UUID
    @Field(key: FieldKeys.v1.languageName) var languageName: String
    @Field(key: FieldKeys.v1.languageCode) var languageCode: String
    @Field(key: FieldKeys.v1.languageIsRTL) var languageIsRTL: Bool
    @OptionalField(key: FieldKeys.v1.languagePriority) var languagePriority: Int?

    init() { }
}

extension WaypointSummaryModel {
    var _$languageCode: FieldProperty<WaypointSummaryModel, String> { $languageCode }
    var _$detailId: FieldProperty<WaypointSummaryModel, UUID> { $detailId }
    var _$detailUserId: OptionalFieldProperty<WaypointSummaryModel, UUID> { $detailUserId }
}

extension WaypointSummaryModel {
    struct Elasticsearch: ElasticModelInterface {
        typealias DatabaseModel = WaypointSummaryModel

        static var baseSchema = "waypoints"
        static var mappings: [String: Any] = [
            "properties": [
                "id": [
                    "type": "keyword",
                ],
                "detailId": [
                    "type": "keyword",
                ],
                "title": [
                    "type": "text",
                    "fields": [
                        "keyword": [
                            "type": "keyword",
                        ],
                        "suggest": [
                            "type": "completion",
                            "analyzer": "default",
                        ],
                    ],
                ],
                "slug": [
                    "type": "keyword",
                ],
                "detailText": [
                    "type": "text",
                ],
                "detailVerifiedAt": [
                    "type": "date",
                ],
                "detailCreatedAt": [
                    "type": "date",
                ],
                "detailUpdatedAt": [
                    "type": "date",
                ],
                "detailDeletedAt": [
                    "type": "date",
                ],
                "locationId": [
                    "type": "keyword",
                ],
                "location": [
                    "type": "geo_point",
                ],
                "locationUserId": [
                    "type": "keyword",
                ],
                "locationVerifiedAt": [
                    "type": "date",
                ],
                "locationCreatedAt": [
                    "type": "date",
                ],
                "locationUpdatedAt": [
                    "type": "date",
                ],
                "locationDeletedAt": [
                    "type": "date",
                ],
                "detailUserId": [
                    "type": "keyword",
                ],
                "languageId": [
                    "type": "keyword",
                ],
                "languageName": [
                    "type": "text",
                    "fields": [
                        "keyword": [
                            "type": "keyword",
                        ],
                    ],
                ],
                "languageCode": [
                    "type": "keyword",
                ],
                "languageIsRTL": [
                    "type": "boolean",
                ],
                "languagePriority": [
                    "type": "short",
                ],
                "tags": [
                    "type": "keyword",
                ],
            ],
        ]

        struct Location: Codable {
            var lat: Double
            var lon: Double
        }

        var id: UUID

        var detailId: UUID
        var title: String
        var slug: String
        var detailText: String
        @NullCodable var detailUserId: UUID?
        var detailVerifiedAt: Date?
        var detailCreatedAt: Date?
        var detailUpdatedAt: Date?
        var detailDeletedAt: Date?

        var locationId: UUID
        var location: Location
        @NullCodable var locationUserId: UUID?
        var locationVerifiedAt: Date?
        var locationCreatedAt: Date?
        var locationUpdatedAt: Date?
        var locationDeletedAt: Date?

        var languageId: UUID
        var languageName: String
        var languageCode: String
        var languageIsRTL: Bool
        var languagePriority: Int?

        var tags: [UUID]
    }

    func toElasticsearch(on db: Database) async throws -> Elasticsearch {
        let tags = try await WaypointTagModel
            .query(on: db)
            .filter(\.$waypoint.$id == requireID())
            .field(\.$tag.$id)
            .all()
            .map(\.$tag.id)
        return try toElasticsearch(tags: tags)
    }

    func toElasticsearch(tags: [UUID]) throws -> Elasticsearch {
        try Elasticsearch(
            id: requireID(),
            detailId: detailId,
            title: title,
            slug: slug,
            detailText: detailText,
            detailUserId: detailUserId,
            detailVerifiedAt: detailVerifiedAt,
            detailCreatedAt: detailCreatedAt,
            detailUpdatedAt: detailUpdatedAt,
            detailDeletedAt: detailDeletedAt,
            locationId: locationId,
            location: Elasticsearch.Location(lat: latitude, lon: longitude),
            locationUserId: locationUserId,
            locationVerifiedAt: locationVerifiedAt,
            locationCreatedAt: locationCreatedAt,
            locationUpdatedAt: locationUpdatedAt,
            locationDeletedAt: locationDeletedAt,
            languageId: languageId,
            languageName: languageName,
            languageCode: languageCode,
            languageIsRTL: languageIsRTL,
            languagePriority: languagePriority,
            tags: tags
        )
    }
}

extension WaypointSummaryModel.Elasticsearch {
    @discardableResult
    static func createOrUpdate(detailsWithRepositoryId repositoryId: UUID, on req: Request) async throws -> ESBulkResponse? {
        let elements = try await DatabaseModel
            .query(on: req.db)
            .filter(\.$id == repositoryId)
            .all()
        guard !elements.isEmpty else { return nil }
        let documents = try await elements
            .concurrentMap { try await $0.toElasticsearch(on: req.db) }
            .map { ESBulkOperation(operationType: .index, index: $0.schema, id: $0.id, document: $0) }
        let response = try await req.elastic.bulk(documents)
        return response
    }

    @discardableResult
    static func deleteUser(_ userId: UUID, on req: Request) async throws -> ESBulkResponse? {
        let elementsToDelete = try await DatabaseModel
            .query(on: req.db)
            .group(.or) { query in
                query
                    .filter(\.$detailUserId == userId)
                    .filter(\.$locationUserId == userId)
            }
            .all()

        guard !elementsToDelete.isEmpty else { return nil }
        let documents = try await elementsToDelete
            .concurrentMap { element in
                var document = try await element.toElasticsearch(on: req.db)
                if document.detailUserId == userId {
                    document.detailUserId = nil
                }
                if document.locationUserId == userId {
                    document.locationUserId = nil
                }
                return document
            }
            .map { (document: Self) in
                ESBulkOperation(operationType: .update, index: document.schema, id: document.id, document: document)
            }
        let response = try await req.elastic.bulk(documents)
        return response
    }

    func getTagList(preferredLanguageCode: String?, on elastic: ElasticHandler) async throws -> [Tag.Detail.List] {
        guard !tags.isEmpty else {
            return []
        }

        var query: [String: Any] = [
            "query": [
                "terms": [
                    "id": tags.map(\.uuidString),
                ],
            ],
            "collapse": [
                "field": "id",
            ],
        ]
        var sort: [[String: Any]] = []
        if let preferredLanguageCode {
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

        return try await elastic.perform {
            guard
                let queryData = try? JSONSerialization.data(withJSONObject: query),
                let responseData = try? await elastic.custom("/\(LatestVerifiedTagModel.Elasticsearch.wildcardSchema)/_search", method: .GET, body: queryData),
                let response = try? ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<LatestVerifiedTagModel.Elasticsearch>.self, from: responseData)
            else {
                throw Abort(.internalServerError)
            }

            return response.hits.hits.map {
                let source = $0.source
                return .init(
                    id: source.id,
                    title: source.title,
                    slug: source.slug
                )
            }
        }
    }
}
