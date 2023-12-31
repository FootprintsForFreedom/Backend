import Fluent
import XCTVapor
@testable import App

protocol MediaTest: WaypointTest { }

extension MediaTest {
    var mediaPath: String { "api/v1/media/" }

    func createNewMedia(
        title: String = "New Media Title \(UUID())",
        detailText: String = "New Media Description",
        source: String = "New Media Source",
        fileType: Media.Detail.FileType = .image,
        verified: Bool = false,
        waypointId: UUID? = nil,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: MediaRepositoryModel, detail: MediaDetailModel, file: MediaFileModel) {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }

        let languageId: UUID = try await {
            if let languageId {
                return languageId
            } else {
                return try await LanguageModel
                    .query(on: app.db)
                    .filter(\.$languageCode == "de")
                    .first()!
                    .requireID()
            }
        }()

        let waypointId: UUID = try await {
            if let waypointId {
                return waypointId
            } else {
                return try await createNewWaypoint(languageId: languageId).repository.requireID()
            }
        }()

        let mediaRepository = MediaRepositoryModel(requiredFileType: fileType)
        mediaRepository.$waypoint.id = waypointId
        try await mediaRepository.create(on: app.db)

        let mediaFile = try await MediaFileModel.createWith(
            mediaDirectory: UUID().uuidString,
            fileType: fileType,
            userId: userId,
            on: app.db
        )

        let mediaDetail = try await MediaDetailModel.createWith(
            verified: false,
            title: title,
            detailText: detailText,
            source: source,
            languageId: languageId,
            repositoryId: mediaRepository.requireID(),
            fileId: mediaFile.requireID(),
            userId: userId,
            on: self
        )

        if verified {
            try app
                .describe("Verify media as moderator should be successful and return ok")
                .post(mediaPath.appending("\(mediaRepository.requireID())/verify/\(mediaDetail.requireID())"))
                .bearerToken(moderatorToken)
                .expect(.ok)
                .expect(.json)
                .expect(Media.Detail.Detail.self) { content in
                    mediaDetail.slug = content.slug
                }
                .test()
        }

        return (mediaRepository, mediaDetail, mediaFile)
    }
}

extension MediaFileModel {
    static func createWith(
        mediaDirectory: String,
        fileType: Media.Detail.FileType,
        userId: UUID,
        on db: Database
    ) async throws -> Self {
        let mediaFile = self.init(
            mediaDirectory: mediaDirectory,
            fileType: fileType,
            userId: userId
        )
        try await mediaFile.create(on: db)
        return mediaFile
    }
}

extension MediaDetailModel {
    static func createWith(
        verified: Bool,
        title: String,
        slug: String? = nil,
        detailText: String,
        source: String,
        languageId: UUID,
        repositoryId: UUID,
        fileId: UUID,
        userId: UUID,
        on test: MediaTest
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let mediaDetail = self.init(
            title: title,
            slug: slug,
            detailText: detailText,
            source: source,
            languageId: languageId,
            repositoryId: repositoryId,
            fileId: fileId,
            userId: userId
        )
        try await mediaDetail.create(on: test.app.db)

        if verified {
            try test.app
                .describe("Verify media as moderator should be successful and return ok")
                .post(test.mediaPath.appending("\(repositoryId)/verify/\(mediaDetail.requireID())"))
                .bearerToken(test.moderatorToken)
                .expect(.ok)
                .expect(.json)
                .expect(Media.Detail.Detail.self) { content in
                    mediaDetail.slug = content.slug
                }
                .test()
        }

        return mediaDetail
    }

    @discardableResult
    func updateWith(
        verifiedAt: Date? = nil,
        title: String = "Updated Media Title \(UUID())",
        slug: String? = nil,
        detailText: String = "Updated Media Description",
        source: String = "Updated Media Source",
        languageId: UUID? = nil,
        fileId: UUID? = nil,
        userId: UUID? = nil,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let mediaDetail = Self(
            verifiedAt: verifiedAt,
            title: title,
            slug: slug,
            detailText: detailText,
            source: source,
            languageId: languageId ?? $language.id,
            repositoryId: $repository.id,
            fileId: fileId ?? $media.id,
            userId: userId ?? $user.id!
        )
        try await mediaDetail.create(on: db)
        return mediaDetail
    }
}
