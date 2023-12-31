import AppApi
import ElasticsearchNIOClient
import Fluent
import Vapor

extension Tag.Detail.List: Content { }
extension Tag.Detail.Detail: Content { }

struct TagApiController: ApiElasticDetailController, ApiElasticPagedListController, ApiRepositoryCreateController, ApiRepositoryUpdateController, ApiRepositoryPatchController, ApiDeleteController {
    typealias ApiModel = Tag.Detail
    typealias DatabaseModel = TagRepositoryModel
    typealias ElasticModel = LatestVerifiedTagModel.Elasticsearch

    // MARK: - Validators

    @AsyncValidatorBuilder
    func createValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<[String]>.required("keywords")
        KeyedContentValidator<String>.required("languageCode")
    }

    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<[String]>.required("keywords")
        KeyedContentValidator<String>.required("languageCode")
    }

    @AsyncValidatorBuilder
    func patchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: true)
        KeyedContentValidator<[String]>.required("keywords", optional: true)
        KeyedContentValidator<UUID>.required("idForTagDetailToPatch")
    }

    // MARK: - Routes

    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("tags")
    }

    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }

    // MARK: - List

    func listOutput(_ req: Request, _ model: ElasticModel) async throws -> Tag.Detail.List {
        .init(
            id: model.id,
            title: model.title,
            slug: model.slug
        )
    }

    // MARK: - Detail

    func detailOutput(_ req: Vapor.Request, _ model: LatestVerifiedTagModel.Elasticsearch, _ availableLanguageCodes: [String]) async throws -> AppApi.Tag.Detail.Detail {
        .init(
            id: model.id,
            title: model.title,
            slug: model.slug,
            keywords: model.keywords,
            languageCode: model.languageCode,
            availableLanguageCodes: availableLanguageCodes,
            detailId: model.detailId
        )
    }

    func detailOutput(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Tag.Detail.Detail {
        try await detail.$language.load(on: req.db)

        return try await .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
            keywords: detail.keywords,
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(req.db),
            detailId: detail.requireID()
        )
    }

    // MARK: - Create

    func beforeCreate(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }

    func createInput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail, _ input: Tag.Detail.Create) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)

        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest, reason: "The language code is invalid")
        }

        let keywords = input.keywords.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        guard !keywords.isEmpty else {
            throw Abort(.badRequest, reason: "The keywords are invalid")
        }

        detail.title = input.title
        detail.keywords = keywords
        detail.$language.id = languageId
        detail.$user.id = user.id
    }

    func createResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(status: .created, for: req)
    }

    // MARK: - Update

    func beforeUpdate(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }

    func updateInput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail, _ input: Tag.Detail.Update) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)

        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest, reason: "The language code is invalid")
        }

        let keywords = input.keywords.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }

        detail.title = input.title
        detail.keywords = keywords
        detail.$language.id = languageId
        detail.$user.id = user.id
    }

    func updateResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(for: req)
    }

    // MARK: - Patch

    func beforePatch(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }

    func patchInput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail, _ input: Tag.Detail.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)

        guard let tagToPatch = try await TagDetailModel.find(input.idForTagDetailToPatch, on: req.db) else {
            throw Abort(.badRequest, reason: "No tag with the given id could be found")
        }
        guard try tagToPatch.$repository.id == repository.requireID() else {
            throw Abort(.badRequest, reason: "Tag to patch needs to be in same repository")
        }

        guard input.title != nil || input.keywords != nil else {
            throw Abort(.badRequest)
        }

        detail.title = input.title ?? tagToPatch.title

        if let keywords = input.keywords {
            let keywords = keywords.compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
            guard !keywords.isEmpty else {
                throw Abort(.badRequest, reason: "The keywords are invalid")
            }
            detail.keywords = keywords
        } else {
            detail.keywords = tagToPatch.keywords
        }

        detail.$language.id = tagToPatch.$language.id
        detail.$user.id = user.id
    }

    func patchResponse(_ req: Request, _ repository: DatabaseModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(for: req)
    }

    // MARK: - Delete

    func beforeDelete(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await req.onlyFor(.moderator)
    }

    func afterDelete(_ req: Request, _ repository: TagRepositoryModel) async throws {
        try await LatestVerifiedTagModel.Elasticsearch.delete(allDetailsWithRepositoryId: repository.requireID(), on: req)
    }
}
