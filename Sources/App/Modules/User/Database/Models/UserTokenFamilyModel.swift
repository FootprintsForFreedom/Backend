import Vapor
import Fluent

final class UserTokenFamilyModel: DatabaseModelInterface, Authenticatable {
    typealias Module = UserModule

    enum FieldKeys {
        enum v1 {
            static var tokenType: FieldKey { "token_type" }
            static var lastTokenRefresh: FieldKey { "last_token_refresh" }
            static var userId: FieldKey { "user_id" }
        }
    }

    @ID() var id: UUID?
    @Enum(key: FieldKeys.v1.tokenType) var tokenType: UserTokenType
    @Field(key: FieldKeys.v1.lastTokenRefresh) var lastTokenRefresh: Date
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel

    init() { }

    init(
        id: UUID? = nil,
        userId: UUID,
        tokenType: UserTokenType
    ) {
        self.id = id
        self.$user.id = userId
        self.tokenType = tokenType
    }
}
