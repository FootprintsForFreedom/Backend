import AppApi
import ElasticsearchNIOClient
import Fluent
import Vapor

final class MediaSummaryModel: DatabaseElasticInterface {
    typealias Module = MediaModule

    static var schema: String = "media_summaries"

    enum FieldKeys {
        enum v1 {
            // MediaDetail
            static var waypointId: FieldKey { "waypoint_id" }
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var detailText: FieldKey { "detail_text" }
            static var source: FieldKey { "source" }
            static var repositoryId: FieldKey { "repository_id" }
            static var mediaId: FieldKey { "media_id" }
            static var detailUserId: FieldKey { "detail_user_id" }
            static var detailVerifiedAt: FieldKey { "detail_verified_at" }
            static var detailCreatedAt: FieldKey { "detail_created_at" }
            static var detailUpdatedAt: FieldKey { "detail_updated_at" }
            static var detailDeletedAt: FieldKey { "detail_deleted_at" }
            static var detailId: FieldKey { "detail_id" }
            // MediaFile
            static var fileId: FieldKey { "file_id" }
            static var mediaDirectory: FieldKey { "media_directory" }
            static var fileType: FieldKey { "file_type" }
            static var fileUserId: FieldKey { "file_user_id" }
            static var fileCreatedAt: FieldKey { "file_created_at" }
            static var fileUpdatedAt: FieldKey { "file_updated_at" }
            static var fileDeletedAt: FieldKey { "file_deleted_at" }
            // Language
            static var languageCode: FieldKey { "language_code" }
            static var languageName: FieldKey { "language_name" }
            static var languageIsRTL: FieldKey { "language_is_rtl" }
            static var languagePriority: FieldKey { "language_priority" }
            static var languageId: FieldKey { "language_id" }
        }
    }

    @ID() var id: UUID?

    @Field(key: FieldKeys.v1.waypointId) var waypointId: UUID
    @Field(key: FieldKeys.v1.detailId) var detailId: UUID
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.detailText) var detailText: String
    @Field(key: FieldKeys.v1.source) var source: String
    @OptionalField(key: FieldKeys.v1.detailUserId) var detailUserId: UUID?
    @OptionalField(key: FieldKeys.v1.detailVerifiedAt) var detailVerifiedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailCreatedAt) var detailCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailUpdatedAt) var detailUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailDeletedAt) var detailDeletedAt: Date?

    @Field(key: FieldKeys.v1.fileId) var fileId: UUID
    @Field(key: FieldKeys.v1.mediaDirectory) var relativeMediaFilePath: String
    @Enum(key: FieldKeys.v1.fileType) var fileType: Media.Detail.FileType
    @OptionalField(key: FieldKeys.v1.fileUserId) var fileUserId: UUID?
    @OptionalField(key: FieldKeys.v1.fileCreatedAt) var fileCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.fileUpdatedAt) var fileUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.fileDeletedAt) var fileDeletedAt: Date?

    @Field(key: FieldKeys.v1.languageId) var languageId: UUID
    @Field(key: FieldKeys.v1.languageName) var languageName: String
    @Field(key: FieldKeys.v1.languageCode) var languageCode: String
    @Field(key: FieldKeys.v1.languageIsRTL) var languageIsRTL: Bool
    @OptionalField(key: FieldKeys.v1.languagePriority) var languagePriority: Int?

    init() { }
}

extension MediaSummaryModel {
    var _$languageCode: FieldProperty<MediaSummaryModel, String> { $languageCode }
    var _$detailId: FieldProperty<MediaSummaryModel, UUID> { $detailId }
    var _$detailUserId: OptionalFieldProperty<MediaSummaryModel, UUID> { $detailUserId }
}

extension MediaSummaryModel {
    struct Elasticsearch: ElasticModelInterface {
        typealias DatabaseModel = MediaSummaryModel

        static var baseSchema = "media"
        static var mappings: [String: Any] = [
            "properties": [
                "id": [
                    "type": "keyword",
                ],
                "waypointId": [
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
                "source": [
                    "type": "text",
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
                "fileId": [
                    "type": "keyword",
                ],
                "relativeMediaFilePath": [
                    "type": "keyword",
                ],
                "fileType": [
                    "type": "keyword",
                ],
                "fileUserId": [
                    "type": "keyword",
                ],
                "fileCreatedAt": [
                    "type": "date",
                ],
                "fileUpdatedAt": [
                    "type": "date",
                ],
                "fileDeletedAt": [
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
                "tags": [
                    "type": "keyword",
                ],
            ],
        ]

        var id: UUID
        var waypointId: UUID

        var detailId: UUID
        var title: String
        var slug: String
        var detailText: String
        var source: String
        @NullCodable var detailUserId: UUID?
        var detailVerifiedAt: Date?
        var detailCreatedAt: Date?
        var detailUpdatedAt: Date?
        var detailDeletedAt: Date?

        var fileId: UUID
        var relativeMediaFilePath: String
        var fileType: Media.Detail.FileType
        @NullCodable var fileUserId: UUID?
        var fileCreatedAt: Date?
        var fileUpdatedAt: Date?
        var fileDeletedAt: Date?

        var languageId: UUID
        var languageName: String
        var languageCode: String
        var languageIsRTL: Bool
        var languagePriority: Int?

        var tags: [UUID]

        /// The relative file path of the thumbnail.
        var relativeThumbnailFilePath: String? {
            if fileType == .audio { return nil }
            return MediaFileModel.relativeThumbnailFilePath(for: relativeMediaFilePath)
        }
    }

    func toElasticsearch(on db: Database) async throws -> Elasticsearch {
        let tags = try await MediaTagModel
            .query(on: db)
            .filter(\.$media.$id == requireID())
            .field(\.$tag.$id)
            .all()
            .map(\.$tag.id)
        return try toElasticsearch(tags: tags)
    }

    func toElasticsearch(tags: [UUID]) throws -> Elasticsearch {
        try Elasticsearch(
            id: requireID(),
            waypointId: waypointId,
            detailId: detailId,
            title: title,
            slug: slug,
            detailText: detailText,
            source: source,
            detailUserId: detailUserId,
            detailVerifiedAt: detailVerifiedAt,
            detailCreatedAt: detailCreatedAt,
            detailUpdatedAt: detailUpdatedAt,
            detailDeletedAt: detailDeletedAt,
            fileId: fileId,
            relativeMediaFilePath: relativeMediaFilePath,
            fileType: fileType,
            fileUserId: fileUserId,
            fileCreatedAt: fileCreatedAt,
            fileUpdatedAt: fileUpdatedAt,
            fileDeletedAt: fileDeletedAt,
            languageId: languageId,
            languageName: languageName,
            languageCode: languageCode,
            languageIsRTL: languageIsRTL,
            languagePriority: languagePriority,
            tags: tags
        )
    }
}

extension MediaSummaryModel.Elasticsearch {
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
                    .filter(\.$fileUserId == userId)
            }
            .all()

        guard !elementsToDelete.isEmpty else { return nil }
        let documents = try await elementsToDelete
            .concurrentMap { element in
                var document = try await element.toElasticsearch(on: req.db)
                if document.detailUserId == userId {
                    document.detailUserId = nil
                }
                if document.fileUserId == userId {
                    document.fileUserId = nil
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
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await elastic.custom("/\(LatestVerifiedTagModel.Elasticsearch.wildcardSchema)/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<LatestVerifiedTagModel.Elasticsearch>.self, from: responseData)

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
