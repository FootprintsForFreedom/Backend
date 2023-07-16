import AppApi
import Fluent
import Vapor

final class WaypointTagModel: DatabaseModelInterface, TagPivot {
    typealias Module = WaypointModule

    enum FieldKeys {
        enum v1 {
            static var status: FieldKey { "status" }
            static var tagId: FieldKey { "tag_id" }
            static var waypointId: FieldKey { "waypoint_id" }
        }
    }

    @ID() var id: UUID?
    @Enum(key: FieldKeys.v1.status) var status: Status

    @Parent(key: FieldKeys.v1.tagId) var tag: TagRepositoryModel
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointRepositoryModel

    init() {
        status = .pending
    }

    init(
        waypoint: WaypointRepositoryModel,
        tag: TagRepositoryModel,
        verifiedAt: Date? = nil
    ) throws {
        self.$waypoint.id = try waypoint.requireID()
        self.$tag.id = try tag.requireID()
        status = status
    }
}

extension WaypointTagModel {
    var _$status: EnumProperty<WaypointTagModel, Status> { $status }
}
