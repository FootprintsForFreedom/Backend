//
//  WaypointApiController+Verify.swift
//  
//
//  Created by niklhut on 01.03.22.
//

import Vapor
import Fluent
import DiffMatchPatch

extension Waypoint.Waypoint.Changes: Content { }

extension WaypointApiController {
    func onlyForModerator(_ req: Request) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require  the user to be a admin or higher
        guard user.role >= .moderator else {
            throw Abort(.forbidden)
        }
    }
    
    // GET: api/wayponts/:repositoryID/changes/?from=model1ID&to=model2ID
    func detailChanges(_ req: Request) async throws -> Waypoint.Waypoint.Changes {
        try await onlyForModerator(req)
        
        let repository = try await detail(req)
        let detailChangesRequest = try req.query.decode(Waypoint.Waypoint.DetailChangesRequest.self)
        
        guard let fromId = detailChangesRequest.from,
              let toId = detailChangesRequest.to
        else {
            throw Abort(.badRequest)
        }
        
        guard let model1 = try await WaypointWaypointModel
                .query(on: req.db)
                .filter(\.$repository.$id == repository.requireID())
                .filter(\._$id == fromId)
                .with(\.$title)
                .with(\.$description)
                .with(\.$location)
                .with(\.$user)
                .first(),
              let model2 = try await WaypointWaypointModel
                .query(on: req.db)
                .filter(\.$repository.$id == repository.requireID())
                .filter(\._$id == toId)
                .with(\.$title)
                .with(\.$description)
                .with(\.$location)
                .with(\.$user)
                .first()
        else {
            throw Abort(.notFound)
        }
        
        /// compute the diffs
        let titleDiff = computeDiff(model1.title.value, model2.title.value)
            .cleaningUpSemantics()
            .converted()
        let descriptionDiff = computeDiff(model1.description.value, model2.description.value)
            .cleaningUpSemantics()
            .converted()
        /// only set the new location if it has changed
        let newLocation = model1.location.value == model2.location.value ? nil : model2.location.value
        
        let model1User = try User.Account.Detail.publicDetail(id: model1.user.requireID(), name: model1.user.name, school: model1.user.school)
        let model2User = try User.Account.Detail.publicDetail(id: model2.user.requireID(), name: model2.user.name, school: model2.user.school)
        return .init(
            titleDiff: titleDiff,
            descriptionDiff: descriptionDiff,
            oldLocation: model1.location.value,
            newLocation: newLocation,
            fromUser: model1User,
            toUser: model2User
        )
        // TODO: also return users who created models
    }
    
    var newWaypointModelPathIdKey: String { "newWaypointModel" }
    var newWaypointModelPathIdComponent: PathComponent { .init(stringLiteral: ":" + newWaypointModelPathIdKey) }
    
    // POST: api/waypoints/:repositoryID/verify/:waypointModelId
    func verifyChanges(_ req: Request) async throws -> Waypoint.Waypoint.Detail {
        try await onlyForModerator(req)
        
        let repository = try await detail(req)
        guard
            let waypointIdString = req.parameters.get(newWaypointModelPathIdKey),
            let waypointId = UUID(uuidString: waypointIdString)
        else {
            throw Abort(.badRequest)
        }
        
        guard let waypoint = try await WaypointWaypointModel
                .query(on: req.db)
                .join(WaypointRepositoryModel.self, on: \WaypointWaypointModel.$repository.$id == \WaypointRepositoryModel.$id)
                .filter(WaypointRepositoryModel.self, \._$id == repository.requireID())
                .filter(\._$id == waypointId)
                .first()
        else {
            throw Abort(.badRequest)
        }
        
        guard !waypoint.verified else {
            throw Abort(.badRequest, reason: "Waypoint Model is already verified")
        }
        
        waypoint.verified = true
        try await waypoint.update(on: req.db)
        try await waypoint.load(on: req.db)
        return try .moderatorDetail(
            id: repository.id!,
            title: waypoint.title.value,
            description: waypoint.description.value,
            location: waypoint.location.value,
            languageCode: waypoint.language.languageCode,
            verified: waypoint.verified,
            modelId: waypoint.requireID()
        )
    }
    
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes
            .grouped("verify")
            .grouped(newWaypointModelPathIdComponent)
            .post(use: verifyChanges)
        
        existingModelRoutes
            .get("changes", use: detailChanges)
    }
}

