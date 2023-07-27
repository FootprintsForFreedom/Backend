import AppApi
import Fluent
import Vapor

extension MediaApiController {
    var tagPathIdKey: String { "tag" }
    var tagPathIdComponent: PathComponent { .init(stringLiteral: ":" + tagPathIdKey) }

    private func getTagId(_ req: Request) throws -> UUID {
        guard
            let tagIdString = req.parameters.get(tagPathIdKey),
            let tagId = UUID(uuidString: tagIdString)
        else {
            throw Abort(.badRequest)
        }
        return tagId
    }

    private func getRepositoryWithDetails(_ req: Request) async throws -> (repository: MediaRepositoryModel, detail: MediaDetailModel) {
        let repository = try await repository(req)
        guard let detail = try await repository._$details.firstFor(req.allLanguageCodesByPriority(), needsToBeVerified: false, on: req.db) else {
            throw Abort(.badRequest)
        }

        return (repository, detail)
    }

    // MARK: - Routes

    func setupTagRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        let tagRoutes = existingModelRoutes.grouped("tags")

        tagRoutes.get("unverified", use: listUnverifiedTags)

        let newTagRoutes = tagRoutes.grouped(tagPathIdComponent)

        newTagRoutes.post(use: addTag)
        newTagRoutes.delete(use: requestRemoveTag)

        let verifyTagRoutes = tagRoutes
            .grouped("verify")
            .grouped(tagPathIdComponent)

        verifyTagRoutes.post(use: verifyAddedTag)
        verifyTagRoutes.delete(use: removeTag)
    }

    // MARK: - add tag

    func addTag(_ req: Request) async throws -> Media.Detail.Detail {
        try await req.onlyForVerifiedUser()
        let (repository, detail) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)

        guard
            let tag = try await TagRepositoryModel.find(tagId, on: req.db),
            try await tag.containsVerifiedDetail(req.db)
        else {
            throw Abort(.badRequest, reason: "The tag needs to be verified")
        }

        try await repository.$tags.attach(tag, method: .ifNotExists, on: req.db)

        return try await detailOutput(req, repository, detail)
    }

    func verifyAddedTag(_ req: Request) async throws -> Media.Detail.Detail {
        try await req.onlyFor(.moderator)
        let (repository, detail) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)

        guard
            let tagPivot = try await repository.$tags.$pivots.query(on: req.db)
            .filter(\.$media.$id == repository.requireID())
            .filter(\.$tag.$id == tagId)
            .first(),
            tagPivot.status == .pending
        else {
            throw Abort(.badRequest)
        }

        tagPivot.status = .verified
        try await tagPivot.save(on: req.db)

        try await MediaSummaryModel.Elasticsearch.createOrUpdate(detailsWithRepositoryId: repository.requireID(), on: req)

        return try await detailOutput(req, repository, detail)
    }

    // MARK: - remove tag

    func requestRemoveTag(_ req: Request) async throws -> Media.Detail.Detail {
        try await req.onlyForVerifiedUser()
        let (repository, detail) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)

        guard
            let tagPivot = try await repository.$tags.$pivots.query(on: req.db)
            .filter(\.$media.$id == repository.requireID())
            .filter(\.$tag.$id == tagId)
            .first(),
            tagPivot.status == .verified
        else {
            throw Abort(.badRequest)
        }

        tagPivot.status = .deleteRequested
        try await tagPivot.save(on: req.db)

        return try await detailOutput(req, repository, detail)
    }

    func removeTag(_ req: Request) async throws -> Media.Detail.Detail {
        try await req.onlyFor(.moderator)
        let (repository, detail) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)

        guard let tag = try await TagRepositoryModel.find(tagId, on: req.db) else {
            throw Abort(.badRequest)
        }

        try await repository.$tags.detach(tag, on: req.db)

        try await MediaSummaryModel.Elasticsearch.createOrUpdate(detailsWithRepositoryId: repository.requireID(), on: req)

        return try await detailOutput(req, repository, detail)
    }

    // MARK: list unverified tags

    func listUnverifiedTags(_ req: Request) async throws -> Fluent.Page<Tag.Repository.ListUnverifiedRelation> {
        try await req.onlyFor(.moderator)
        let repository = try await repository(req)

        let unverifiedTags = try await repository.$tags.$pivots
            .query(on: req.db)
            .filter(\.$status ~~ [.pending, .deleteRequested])
            .paginate(for: req)

        return try await unverifiedTags.concurrentMap { tag in
            let repository = try await tag.$tag.get(on: req.db)
            guard let detail = try await repository._$details.firstFor(req.allLanguageCodesByPriority(), needsToBeVerified: false, on: req.db) else {
                throw Abort(.internalServerError)
            }
            try await detail.$language.load(on: req.db)
            return try .init(
                tagId: repository.requireID(),
                title: detail.title,
                slug: detail.slug,
                status: tag.status,
                languageCode: detail.language.languageCode
            )
        }
    }
}
