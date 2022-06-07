//
//  WaypointLocationModel.swift
//  
//
//  Created by niklhut on 19.03.22.
//

import Vapor
import Fluent

final class WaypointLocationModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var status: FieldKey { "status" }
            static var latitude: FieldKey { "latitude" }
            static var longitude: FieldKey { "longitude" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    
    @ID() var id: UUID?
    @Enum(key: FieldKeys.v1.status) var status: Status
    
    @Field(key: FieldKeys.v1.latitude) var latitude: Double
    @Field(key: FieldKeys.v1.longitude) var longitude: Double
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: WaypointRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() {
        self.status = .pending
    }
    
    init(
        id: UUID? = nil,
        status: Status = .pending,
        latitude: Double,
        longitude: Double,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension WaypointLocationModel {
    var location: Waypoint.Location {
        .init(latitude: self.latitude, longitude: self.longitude)
    }
}

extension WaypointLocationModel {
    static func `for`(
        repositoryWithID repositoryId: UUID,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> WaypointLocationModel? {
        let verifiedLocation = try await WaypointLocationModel
            .query(on: db)
            .filter(\.$repository.$id == repositoryId)
            .filter(\.$status ~~ [.verified, .deleteRequested])
            .sort(\.$updatedAt, sortDirection)
            .first()
        
        if let verifiedLocation = verifiedLocation {
            return verifiedLocation
        } else if needsToBeVerified == false {
            return try await WaypointLocationModel
                .query(on: db)
                .filter(\.$repository.$id == repositoryId)
                .sort(\.$updatedAt, sortDirection)
                .first()
        } else {
            return nil
        }
    }
}
