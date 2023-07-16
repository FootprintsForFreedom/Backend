import Fluent
import Vapor

final class UserTokenModel: DatabaseModelInterface {
    typealias Module = UserModule

    enum FieldKeys {
        enum v1 {
            static var value: FieldKey { "value" }
            static var userId: FieldKey { "user_id" }
        }
    }

    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.value) var value: String
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel

    init() { }

    init(id: UUID? = nil,
         value: String,
         userId: UUID)
    {
        self.id = id
        self.value = value
        $user.id = userId
    }
}
