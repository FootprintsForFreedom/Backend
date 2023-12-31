import Fluent
import Spec
import XCTVapor
@testable import App

extension MediaApiListUnverifiedTests: TagTest {
    func testSuccessfulListRepositoriesWithUnverifiedModelsReturnsModelsWithUnverifiedTags() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia(verified: true)

        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)

        let mediaCount = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .count()

        try app
            .describe("List repositories with unverified models should also return repositories with unverified tag connections")
            .get(mediaPath.appending("unverified/?per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }

    func testSuccessfulListRepositoriesWithUnverifiedModelsReturnsModelsWithRequestDeletedTags() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia(verified: true)

        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)

        let tagPivot = try await media.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == media.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .deleteRequested
        try await tagPivot.save(on: app.db)

        let mediaCount = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .count()

        try app
            .describe("List repositories with unverified models should also return repositories with a tag that was requested to be deleted")
            .get(mediaPath.appending("unverified/?per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
}
