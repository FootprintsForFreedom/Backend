//
//  WaypointSummaryModel.swift
//  
//
//  Created by niklhut on 13.09.22.
//

import Vapor
import Fluent

final class WaypointSummaryModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    static var schema: String = "waypoint_summaries"
    
    struct FieldKeys {
        struct v1 {
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
    struct Elasticsearch: ElasticsearchModelInterface {
        struct Delete: Codable, LockKey { }
        
        static var schema = "waypoints"
        
        var id: UUID
        
        var detailId: UUID
        var title: String
        var slug: String
        var detailText: String
        var detailUserId: UUID?
        var detailVerifiedAt: Date?
        var detailCreatedAt: Date?
        var detailUpdatedAt: Date?
        var detailDeletedAt: Date?
        
        var locationId: UUID
        var latitude: Double
        var longitude: Double
        var locationUserId: UUID?
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
    
    func toElasticsearch(tags: [UUID]) throws -> Elasticsearch {
        try Elasticsearch(
            id: self.requireID(),
            detailId: self.detailId,
            title: self.title,
            slug: self.slug,
            detailText: self.detailText,
            detailUserId: self.detailUserId,
            detailVerifiedAt: self.detailVerifiedAt,
            detailCreatedAt: self.detailCreatedAt,
            detailUpdatedAt: self.detailUpdatedAt,
            detailDeletedAt: self.detailDeletedAt,
            locationId: self.locationId,
            latitude: self.latitude,
            longitude: self.longitude,
            locationUserId: self.locationUserId,
            locationVerifiedAt: self.locationVerifiedAt,
            locationCreatedAt: self.locationCreatedAt,
            locationUpdatedAt: self.locationUpdatedAt,
            locationDeletedAt: self.locationDeletedAt,
            languageId: self.languageId,
            languageName: self.languageName,
            languageCode: self.languageCode,
            languageIsRTL: self.languageIsRTL,
            languagePriority: self.languagePriority,
            tags: tags
        )
    }
}
