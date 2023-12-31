import Fluent
import Vapor

final class WaypointDetailModel: TitledDetailModel {
    typealias Module = WaypointModule

    enum FieldKeys {
        enum v1 {
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var detailText: FieldKey { "detail_text" }
            static var languageId: FieldKey { "language_id" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var verifiedAt: FieldKey { "verified_at" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }

    @ID() var id: UUID?

    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.detailText) var detailText: String

    // TODO: likes as sibling?

    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel

    @Parent(key: FieldKeys.v1.repositoryId) var repository: WaypointRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?

    @OptionalField(key: FieldKeys.v1.verifiedAt) var verifiedAt: Date?

    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?

    // MARK: soft delete

    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?

    init() { }

    init(
        id: UUID? = nil,
        verifiedAt: Date? = nil,
        title: String,
        slug: String,
        detailText: String,
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.verifiedAt = verifiedAt
        self.title = title
        self.slug = slug
        self.detailText = detailText
        $language.id = languageId
        $repository.id = repositoryId
        $user.id = userId
    }
}

extension WaypointDetailModel {
    var _$language: ParentProperty<WaypointDetailModel, LanguageModel> { $language }
    var _$verifiedAt: OptionalFieldProperty<WaypointDetailModel, Date> { $verifiedAt }
    var _$updatedAt: TimestampProperty<WaypointDetailModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<WaypointDetailModel, DefaultTimestampFormat> { $deletedAt }
    var _$repository: ParentProperty<WaypointDetailModel, WaypointRepositoryModel> { $repository }
    var _$user: OptionalParentProperty<WaypointDetailModel, UserAccountModel> { $user }
    var _$slug: FieldProperty<WaypointDetailModel, String> { $slug }
}

extension WaypointDetailModel: Equatable {
    static func == (lhs: WaypointDetailModel, rhs: WaypointDetailModel) -> Bool {
        lhs.id == rhs.id
    }
}
