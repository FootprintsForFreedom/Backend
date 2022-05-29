//
//  TagRepositoryModel.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent

final class TagRepositoryModel: RepositoryModel {
    typealias Module = TagModule
    
    static var identifier = "repositories"
    
    struct FieldKeys {
        struct v1 {
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Children(for: \.$repository) var details: [TagDetailModel]
    
    @Siblings(through: WaypointTagModel.self, from: \.$tag, to: \.$waypoint) var waypoints: [WaypointRepositoryModel]
    @Siblings(through: MediaTagModel.self, from: \.$tag, to: \.$media) var media: [MediaRepositoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
}

extension TagRepositoryModel {
    var _$details: ChildrenProperty<TagRepositoryModel, TagDetailModel> { $details }
}

extension TagRepositoryModel {
    func deleteDependencies(on database: Database) async throws {
        try await $details
            .query(on: database)
            .delete()
    }
}
