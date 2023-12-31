import Fluent
import Spec
import XCTVapor
@testable import App

final class MediaApiAddTagTests: AppTestCase, MediaTest, TagTest {
    func testSuccessfulAddTagToMedia() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.detail.$language.load(on: app.db)

        try app
            .describe("Add tag to media should return ok and the media")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, media.repository.id)
                XCTAssertEqual(content.title, media.detail.title)
                XCTAssertEqual(content.detailText, media.detail.detailText)
                XCTAssertEqual(content.languageCode, media.detail.language.languageCode)
                XCTAssertEqual(content.fileType, media.file.fileType)
                XCTAssertEqual(content.filePath, media.file.relativeMediaFilePath)
                XCTAssert(!content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }

    func testAddTagToMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()

        try app
            .describe("Add tag to media as unverified user should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }

    func testAddTagToMediasWithoutTokenFails() async throws {
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()

        try app
            .describe("Add tag to media requires verified tag")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }

    func testAddTagToMediasNeedsValidMediaId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verified: true)

        try app
            .describe("Add tag to media requires valid (but not necessarily verified) media id")
            .post(mediaPath.appending("\(UUID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.notFound)
            .test()
    }

    func testAddTagToMediasNeedsVerifiedTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let media = try await createNewMedia()

        try app
            .describe("Add tag to media requires verified tag")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
