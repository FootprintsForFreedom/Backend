import Fluent
import Vapor

final class LatestVerifiedTagModel: DatabaseElasticInterface {
    typealias Module = TagModule

    static var schema: String = "latest_verified_tag_details"

    enum FieldKeys {
        enum v1 {
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var keywords: FieldKey { "keywords" }
            static var detailUserId: FieldKey { "detail_user_id" }
            static var detailVerifiedAt: FieldKey { "detail_verified_at" }
            static var detailCreatedAt: FieldKey { "detail_created_at" }
            static var detailUpdatedAt: FieldKey { "detail_updated_at" }
            static var detailDeletedAt: FieldKey { "detail_deleted_at" }
            static var detailId: FieldKey { "detail_id" }
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
    @Field(key: FieldKeys.v1.keywords) var keywords: [String]
    @OptionalField(key: FieldKeys.v1.detailUserId) var detailUserId: UUID?
    @OptionalField(key: FieldKeys.v1.detailVerifiedAt) var detailVerifiedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailCreatedAt) var detailCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailUpdatedAt) var detailUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailDeletedAt) var detailDeletedAt: Date?

    @Field(key: FieldKeys.v1.languageId) var languageId: UUID
    @Field(key: FieldKeys.v1.languageName) var languageName: String
    @Field(key: FieldKeys.v1.languageCode) var languageCode: String
    @Field(key: FieldKeys.v1.languageIsRTL) var languageIsRTL: Bool
    @OptionalField(key: FieldKeys.v1.languagePriority) var languagePriority: Int?

    init() { }
}

extension LatestVerifiedTagModel {
    var _$languageCode: FieldProperty<LatestVerifiedTagModel, String> { $languageCode }
    var _$detailId: FieldProperty<LatestVerifiedTagModel, UUID> { $detailId }
    var _$detailUserId: OptionalFieldProperty<LatestVerifiedTagModel, UUID> { $detailUserId }
}

extension LatestVerifiedTagModel {
    struct Elasticsearch: ElasticModelInterface {
        typealias DatabaseModel = LatestVerifiedTagModel
        struct Key: Codable, LockKey { }

        static var baseSchema = "tags"
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
                "keywords": [
                    "type": "text",
                    "fields": [
                        "keyword": [
                            "type": "keyword",
                        ],
                    ],
                ],
                "detailUserId": [
                    "type": "keyword",
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
            ],
        ]

        var id: UUID

        var detailId: UUID
        var title: String
        var slug: String
        var keywords: [String]
        @NullCodable var detailUserId: UUID?
        var detailVerifiedAt: Date?
        var detailCreatedAt: Date?
        var detailUpdatedAt: Date?
        var detailDeletedAt: Date?

        var languageId: UUID
        var languageName: String
        var languageCode: String
        var languageIsRTL: Bool
        var languagePriority: Int?
    }

    func toElasticsearch(on db: Database) async throws -> Elasticsearch {
        try toElasticsearch()
    }

    func toElasticsearch() throws -> Elasticsearch {
        try Elasticsearch(
            id: requireID(),
            detailId: detailId,
            title: title,
            slug: slug,
            keywords: keywords,
            detailUserId: detailUserId,
            detailVerifiedAt: detailVerifiedAt,
            detailCreatedAt: detailCreatedAt,
            detailUpdatedAt: detailUpdatedAt,
            detailDeletedAt: detailDeletedAt,
            languageId: languageId,
            languageName: languageName,
            languageCode: languageCode,
            languageIsRTL: languageIsRTL,
            languagePriority: languagePriority
        )
    }
}
