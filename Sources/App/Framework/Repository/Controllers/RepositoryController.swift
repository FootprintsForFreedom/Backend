//
//  RepositoryController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryController: ModelController where DatabaseModel: RepositoryModel, DatabaseModel.Detail.Repository == DatabaseModel {
    /// The database detail model.
    typealias Detail = DatabaseModel.Detail
    
    /// Gets the model slug from a request.
    /// - Parameter req: The request containing the model slug.
    /// - Returns: The model slug.
    func slug(_ req: Request) throws -> String
    
    /// Finds a detail by its slug on the database.
    /// - Parameters:
    ///   - slug: The detail slug.
    ///   - on: The database on which to find the detail model.
    /// - Returns: The detail model with the given slug.
    func findBy(_ slug: String, on db: Database) async throws -> Detail
    
    /// Gets a repository from a request.
    /// - Parameter req: The request of which to get the repository model.
    /// - Returns: The repository model given in the request.
    func repository(_ req: Request) async throws -> DatabaseModel
}

extension RepositoryController where DatabaseModel: Reportable  {
    /// The database report model.
    typealias Report = DatabaseModel.Report
}

extension RepositoryController {
    func slug(_ req: Request) throws -> String {
        guard
            let slug = req.parameters.get(ApiModel.pathIdKey),
            slug == slug.slugify()
        else {
            throw Abort(.badRequest)
        }
        return slug
    }
    
    func findBy(_ slug: String, on db: Database) async throws -> Detail {
        guard let detail = try await Detail
            .query(on: db)
            .filter(\._$slug == slug)
            .first()
        else {
            throw Abort(.notFound)
        }
        return detail
    }
    
    func repository(_ req: Request) async throws -> DatabaseModel {
        return try await findBy(identifier(req), on: req.db)
    }
}
