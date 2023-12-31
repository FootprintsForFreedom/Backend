import Fluent
import Spec
import XCTVapor
@testable import App

extension Media.Detail.Patch: Content { }

final class MediaApiPatchTests: AppTestCase, MediaTest {
    private func getMediaPatchContent(
        title: String = "New Meidia Title \(UUID())",
        patchedTitle: String? = nil,
        detailText: String = "New Media Description",
        patchedDetailText: String? = nil,
        source: String = "New Media Source",
        patchedSource: String? = nil,
        languageId: UUID? = nil,
        waypointId: UUID? = nil,
        verified: Bool = false
    ) async throws -> (mediaRepository: MediaRepositoryModel, createdMediaDetail: MediaDetailModel, createdMediaFile: MediaFileModel, patchContent: Media.Detail.Patch) {
        let (repository, detail, file) = try await createNewMedia(
            title: title,
            detailText: detailText,
            source: source,
            verified: verified,
            waypointId: waypointId,
            languageId: languageId
        )

        let patchContent = try Media.Detail.Patch(
            title: patchedTitle,
            detailText: patchedDetailText,
            source: patchedSource,
            idForMediaDetailToPatch: detail.requireID()
        )
        return (repository, detail, file, patchContent)
    }

    func testSuccessfulPatchMediaTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, file, patchContent) = try await getMediaPatchContent(patchedTitle: "The patched title", verified: true)
        try await detail.$language.load(on: app.db)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media title should return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertNotEqual(content.slug, patchContent.title!.slugify())
                XCTAssertContains(content.slug, patchContent.title!.slugify())
                XCTAssertEqual(content.detailText, detail.detailText)
                XCTAssertEqual(content.source, detail.source)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertEqual(content.fileType, file.fileType)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
            }
            .test()

        // Test the new media model was created correctly
        let newMediaModel = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!

        XCTAssertNotNil(newMediaModel.id)
        XCTAssertNil(newMediaModel.verifiedAt)
    }

    func testSuccessfulPatchMediaTitleWithDuplicateTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let title = "My new title \(UUID())"
        let (repository, detail, file, patchContent) = try await getMediaPatchContent(title: title, patchedTitle: title, verified: true)
        try await detail.$language.load(on: app.db)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media title should return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertNotEqual(content.slug, patchContent.title!.slugify())
                XCTAssertContains(content.slug, patchContent.title!.slugify())
                XCTAssertEqual(content.detailText, detail.detailText)
                XCTAssertEqual(content.source, detail.source)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertEqual(content.fileType, file.fileType)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
            }
            .test()
    }

    func testSuccessfulPatchMediaDetail() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, file, patchContent) = try await getMediaPatchContent(patchedDetailText: "The patched detailText", verified: true)
        try await detail.$language.load(on: app.db)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media title detailText return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertNotEqual(content.slug, detail.title.slugify())
                XCTAssertContains(content.slug, detail.title.slugify())
                XCTAssertEqual(content.detailText, patchContent.detailText)
                XCTAssertEqual(content.source, detail.source)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertEqual(content.fileType, file.fileType)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
            }
            .test()

        // Test the new media model was created correctly
        let newMediaModel = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!

        XCTAssertNotNil(newMediaModel.id)
        XCTAssertNil(newMediaModel.verifiedAt)
    }

    func testSuccessfulPatchMediaSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, file, patchContent) = try await getMediaPatchContent(patchedSource: "The patched source", verified: true)
        try await detail.$language.load(on: app.db)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media source should return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertNotEqual(content.slug, detail.title.slugify())
                XCTAssertContains(content.slug, detail.title.slugify())
                XCTAssertEqual(content.detailText, detail.detailText)
                XCTAssertEqual(content.source, patchContent.source)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertEqual(content.fileType, file.fileType)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
            }
            .test()

        // Test the new media model was created correctly
        let newMediaModel = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!

        XCTAssertNotNil(newMediaModel.id)
        XCTAssertNil(newMediaModel.verifiedAt)
    }

    func testSuccessfulPatchMediaFile() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, file, patchContent) = try await getMediaPatchContent(verified: true)
        try await detail.$language.load(on: app.db)

        let query = try URLEncodedFormEncoder().encode(patchContent)
        let newFile = FileUtils.testImage

        try app
            .describe("Patch media file should return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(FileUtils.data(for: newFile))
            .header("Content-Type", newFile.mimeType)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertNotEqual(content.slug, detail.title.slugify())
                XCTAssertContains(content.slug, detail.title.slugify())
                XCTAssertEqual(content.detailText, detail.detailText)
                XCTAssertEqual(content.source, detail.source)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertEqual(content.fileType, file.fileType)
                XCTAssertNotEqual(content.filePath, file.relativeMediaFilePath)
            }
            .test()

        // Test the new media model was created correctly
        let newMediaModel = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!

        XCTAssertNotNil(newMediaModel.id)
        XCTAssertNil(newMediaModel.verifiedAt)
    }

    func testEmptyPatchMediaFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media with empty payload should fail")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaWithIdFromOtherRepositoryFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _) = try await createNewMedia(fileType: .document, verified: true)
        let (_, _, _, patchContent) = try await getMediaPatchContent(patchedTitle: UUID().uuidString, verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media with media id from other repository should fail")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedTitle: "", verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media title should need valid title or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaNeedsValidDetailText() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedDetailText: "", verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media title should need valid detailText or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaNeedsValidSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedSource: "", verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media title should need valid source or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaNeedsRequiredContentType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)
        let file = FileUtils.testFile(excludedFileType: repository.requiredFileType)

        try app
            .describe("Update media should return ok")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(FileUtils.data(for: file))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaNeedsValidIdForMediaDetailToPatch() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, _) = try await getMediaPatchContent(verified: true)
        let patchContent = Media.Detail.Patch(title: nil, detailText: nil, source: nil, idForMediaDetailToPatch: UUID())

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media should need valid id for media to patch or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaFileNeedsValidContentType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)
        let file = FileUtils.testImage

        try app
            .describe("Patch media should need valid content type or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(FileUtils.data(for: file))
            .header("Content-Type", "hallo/test")
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testUpdateMediaNeedsFileWithRequiredMediaType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaPatchContent(verified: true)

        let query = try URLEncodedFormEncoder().encode(updateContent)
        let file = FileUtils.testDocument

        try app
            .describe("Update media should need media content type or fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedSource: "Another source", verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media as unverified user should fail")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }

    func testPatchMediaWithoutTokenFails() async throws {
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedTitle: "My new Title", verified: true)

        let query = try URLEncodedFormEncoder().encode(patchContent)

        try app
            .describe("Patch media wihtout token should fail")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .expect(.unauthorized)
            .test()
    }
}
