import Fluent
import Vapor

final class MediaReportModel: ReportModel {
    typealias Module = MediaModule

    enum FieldKeys {
        enum v1 {
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var reason: FieldKey { "reason" }
            static var visibleDetailId: FieldKey { "visible_detail_id" }
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
    @Field(key: FieldKeys.v1.reason) var reason: String

    @OptionalParent(key: FieldKeys.v1.visibleDetailId) var visibleDetail: MediaDetailModel?
    @Parent(key: FieldKeys.v1.repositoryId) var repository: MediaRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?

    @OptionalField(key: FieldKeys.v1.verifiedAt) var verifiedAt: Date?

    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?

    // MARK: soft delete

    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?

    init() { }

    init(
        verifiedAt: Date?,
        title: String,
        slug: String,
        reason: String,
        visibleDetailId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.verifiedAt = verifiedAt
        self.title = title
        self.slug = slug
        self.reason = reason
        $visibleDetail.id = visibleDetailId
        $repository.id = repositoryId
        $user.id = userId
    }
}

extension MediaReportModel {
    var _$slug: FieldProperty<MediaReportModel, String> { $slug }
    var _$reason: FieldProperty<MediaReportModel, String> { $reason }
    var _$visibleDetail: OptionalParentProperty<MediaReportModel, MediaDetailModel> { $visibleDetail }
    var _$repository: ParentProperty<MediaReportModel, MediaRepositoryModel> { $repository }
    var _$user: OptionalParentProperty<MediaReportModel, UserAccountModel> { $user }
    var _$verifiedAt: OptionalFieldProperty<MediaReportModel, Date> { $verifiedAt }
    var _$updatedAt: TimestampProperty<MediaReportModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<MediaReportModel, DefaultTimestampFormat> { $deletedAt }
}
