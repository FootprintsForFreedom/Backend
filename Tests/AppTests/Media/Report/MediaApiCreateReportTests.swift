import Fluent
import Spec
import XCTVapor
@testable import App

final class MediaApiCreateReportTests: AppTestCase, MediaTest {
    func getMediaReportCreateContent(
        title: String = "I don't like this",
        reason: String = "Just because",
        visibleDetailId: UUID
    ) -> Report.Create {
        .init(title: title, reason: reason, visibleDetailId: visibleDetailId)
    }

    func testSuccessfulCreateReport() async throws {
        let token = try await getToken(for: .user, verified: true)
        let media = try await createNewMedia()
        let newReport = try getMediaReportCreateContent(visibleDetailId: media.detail.requireID())
        try await media.detail.$language.load(on: app.db)

        try app
            .describe("Create new report as verified user should return ok")
            .post(mediaPath.appending("\(media.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.created)
            .expect(.json)
            .expect(Report.Detail<Media.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, newReport.title)
                XCTAssertContains(content.slug, newReport.title.slugify())
                XCTAssertEqual(content.reason, newReport.reason)
                XCTAssertNotNil(content.visibleDetail)
                if let visibleDetail = content.visibleDetail {
                    XCTAssertEqual(visibleDetail.id, media.repository.id)
                    XCTAssertEqual(visibleDetail.title, media.detail.title)
                    XCTAssertEqual(visibleDetail.slug, media.detail.slug)
                    XCTAssertEqual(visibleDetail.detailText, media.detail.detailText)
                    XCTAssertEqual(visibleDetail.languageCode, media.detail.language.languageCode)
                    XCTAssertEqual(visibleDetail.fileType, media.file.fileType)
                    XCTAssertEqual(visibleDetail.filePath, media.file.relativeMediaFilePath)
                    XCTAssertNotNil(visibleDetail.detailId)
                }
            }
            .test()
    }

    func testCreateReportAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let media = try await createNewMedia()
        let newReport = try getMediaReportCreateContent(visibleDetailId: media.detail.requireID())
        try await media.detail.$language.load(on: app.db)

        try app
            .describe("Create new report as unverified user should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }

    func testCreateReportWithoutTokenFails() async throws {
        let media = try await createNewMedia()
        let newReport = try getMediaReportCreateContent(visibleDetailId: media.detail.requireID())
        try await media.detail.$language.load(on: app.db)

        try app
            .describe("Create new report without token should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/reports"))
            .body(newReport)
            .expect(.unauthorized)
            .test()
    }

    func testCreateReportNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let media = try await createNewMedia()
        let newReport = try getMediaReportCreateContent(title: "", visibleDetailId: media.detail.requireID())
        try await media.detail.$language.load(on: app.db)

        try app
            .describe("Create new report should require valid title and fail")
            .post(mediaPath.appending("\(media.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testCreateReportNeedsValidReason() async throws {
        let token = try await getToken(for: .user, verified: true)
        let media = try await createNewMedia()
        let newReport = try getMediaReportCreateContent(reason: "", visibleDetailId: media.detail.requireID())
        try await media.detail.$language.load(on: app.db)

        try app
            .describe("Create new report should require valid reason and fail")
            .post(mediaPath.appending("\(media.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testCreateReportNeedsValidVisibleDetailId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let media = try await createNewMedia()
        let media2 = try await createNewMedia()
        let newReport = try getMediaReportCreateContent(visibleDetailId: media.detail.requireID())
        try await media.detail.$language.load(on: app.db)

        try app
            .describe("Create new report should require valid visible detail id and fail")
            .post(mediaPath.appending("\(media2.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
