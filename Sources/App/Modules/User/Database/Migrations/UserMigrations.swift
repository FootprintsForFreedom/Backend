import AppApi
import Fluent
import Vapor

enum UserMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            let userRole = try await db.enum(User.Role.pathKey)
                .case(User.Role.user.rawValue)
                .case(User.Role.moderator.rawValue)
                .case(User.Role.admin.rawValue)
                .case(User.Role.superAdmin.rawValue)
                .create()

            let tokenType = try await db.enum(UserTokenType.schema)
                .case(UserTokenType.contentAccess.rawValue)
                .case(UserTokenType.tokenRefresh.rawValue)
                .case(UserTokenType.verification.rawValue)
                .create()

            try await db.schema(UserAccountModel.schema)
                .id()
                .field(UserAccountModel.FieldKeys.v1.name, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.email, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.school, .string)
                .field(UserAccountModel.FieldKeys.v1.password, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.verified, .bool, .sql(.default(false)))
                .field(UserAccountModel.FieldKeys.v1.role, userRole, .required)
                .unique(on: UserAccountModel.FieldKeys.v1.email)
                .create()

            try await db.schema(UserTokenFamilyModel.schema)
                .id()
                .field(UserTokenFamilyModel.FieldKeys.v1.tokenType, tokenType, .required)
                .field(UserTokenFamilyModel.FieldKeys.v1.lastTokenRefresh, .datetime, .required)
                .field(UserTokenFamilyModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(UserTokenFamilyModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .cascade)
                .create()

            try await db.schema(UserVerificationTokenModel.schema)
                .id()
                .field(UserVerificationTokenModel.FieldKeys.v1.value, .string, .required)
                .field(UserVerificationTokenModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(UserVerificationTokenModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(UserVerificationTokenModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .cascade)
                .unique(on: UserVerificationTokenModel.FieldKeys.v1.value)
                .unique(on: UserVerificationTokenModel.FieldKeys.v1.userId)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(UserTokenFamilyModel.schema).delete()
            try await db.schema(UserVerificationTokenModel.schema).delete()
            try await db.schema(UserAccountModel.schema).delete()
            try await db.enum(User.Role.pathKey).delete()
            try await db.enum(UserTokenType.schema).delete()
        }
    }

    struct seed: AsyncMigration {
        func prepare(on db: Database) async throws {
            let email = "root@localhost.com"
            let password = "ChangeMe1"
            let user = try UserAccountModel(name: "MyAdmin", email: email, school: "schule", password: Bcrypt.hash(password), verified: true, role: .superAdmin)
            user.role = .superAdmin
            try await user.create(on: db)
        }

        func revert(on db: Database) async throws {
            try await UserAccountModel.query(on: db).delete()
        }
    }
}
