import AppApi
import Fluent
import Vapor

extension User.Account.List: Content { }
extension User.Account.Detail: Content { }

struct UserApiController: ApiController {
    typealias ApiModel = User.Account
    typealias DatabaseModel = UserAccountModel

    // MARK: - Validators

    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("name", optional: optional)
        KeyedContentValidator<String>.email("email", nil, optional)
    }

    // MARK: - Routes

    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(protectedRoutes)
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }

    // MARK: - List

    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<UserAccountModel>) async throws -> QueryBuilder<UserAccountModel> {
        try await req.onlyFor(.admin)
        return queryBuilder
    }

    func listOutput(_ req: Request, _ models: Fluent.Page<UserAccountModel>) async throws -> Fluent.Page<User.Account.List> {
        models.map { model in
            .init(id: model.id!, name: model.name, school: model.school, verified: model.verified, role: model.role)
        }
    }

    // MARK: - Detail

    func detailOutput(_ req: Request, _ model: UserAccountModel) async throws -> User.Account.Detail {
        if let user = req.auth.get(AuthenticatedUser.self) {
            if user.id == model.id || user.role >= .superAdmin {
                return try model.ownDetail()
            } else if user.role >= .admin {
                return try model.adminDetail()
            }
        }
        return try model.publicDetail()
    }

    // MARK: - Create

    func createInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Create) async throws {
        model.name = input.name
        model.email = input.email
        model.school = input.school
        try model.setPassword(to: input.password, on: req)
        model.verified = false
        model.role = .user
    }

    func createResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        try await model.ownDetail().encodeResponse(status: .created, for: req)
    }

    func afterCreate(_ req: Request, _ model: UserAccountModel) async throws {
        let signedVerificationToken = try await model.createSignedVerificationToken(on: req)
        try await UserCreateAccountTemplate.send(for: model, with: signedVerificationToken, on: req)
    }

    // MARK: - Update

    func beforeUpdate(_ req: Request, _ model: UserAccountModel) async throws {
        try await req.onlyFor(model, or: .admin)
    }

    /// Only use this when all fields are updated
    func updateInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Update) async throws {
        let previousEmail = model.email
        model.name = input.name
        model.email = input.email
        model.school = input.school
        if previousEmail != model.email {
            model.verified = false
            let signedVerificationToken = try await model.createSignedVerificationToken(on: req)
            try await UserUpdateEmailAccountTemplate.send(for: model, with: signedVerificationToken, on: req)
        }
    }

    // MARK: - Patch

    func beforePatch(_ req: Request, _ model: UserAccountModel) async throws {
        try await req.onlyFor(model, or: .admin)
    }

    func patchInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Patch) async throws {
        let previousEmail = model.email
        model.name = input.name ?? model.name
        model.email = input.email ?? model.email
        if let setSchool = input.setSchool, setSchool {
            model.school = input.school
        }
        if previousEmail != model.email {
            model.verified = false
            let signedVerificationToken = try await model.createSignedVerificationToken(on: req)
            try await UserUpdateEmailAccountTemplate.send(for: model, with: signedVerificationToken, on: req)
        }
    }

    // MARK: - Delete

    func beforeDelete(_ req: Request, _ model: UserAccountModel) async throws {
        try await ElasticModule.deleteUser(model.requireID(), on: req)

        try await req.onlyFor(model, or: .admin)
    }
}
