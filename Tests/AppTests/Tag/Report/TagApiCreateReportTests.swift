import Fluent
import Spec
import XCTVapor
@testable import App

extension Report.Create: Content { }

final class TagApiCreateReportTests: AppTestCase, TagTest {
    func getTagReportCreateContent(
        title: String = "I don't like this",
        reason: String = "Just because",
        visibleDetailId: UUID
    ) -> Report.Create {
        .init(title: title, reason: reason, visibleDetailId: visibleDetailId)
    }

    func testSuccessfulCreateReport() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let newReport = try getTagReportCreateContent(visibleDetailId: tag.detail.requireID())
        try await tag.detail.$language.load(on: app.db)

        try app
            .describe("Create new report as verified user should return ok")
            .post(tagPath.appending("\(tag.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.created)
            .expect(.json)
            .expect(Report.Detail<Tag.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, newReport.title)
                XCTAssertContains(content.slug, newReport.title.slugify())
                XCTAssertEqual(content.reason, newReport.reason)
                XCTAssertNotNil(content.visibleDetail)
                if let visibleDetail = content.visibleDetail {
                    XCTAssertEqual(visibleDetail.id, tag.repository.id)
                    XCTAssertEqual(visibleDetail.title, tag.detail.title)
                    XCTAssertEqual(visibleDetail.slug, tag.detail.slug)
                    XCTAssertEqual(visibleDetail.keywords, tag.detail.keywords)
                    XCTAssertEqual(visibleDetail.languageCode, tag.detail.language.languageCode)
                    XCTAssertNotNil(visibleDetail.detailId)
                }
            }
            .test()
    }

    func testCreateReportAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let tag = try await createNewTag()
        let newReport = try getTagReportCreateContent(visibleDetailId: tag.detail.requireID())
        try await tag.detail.$language.load(on: app.db)

        try app
            .describe("Create new report as unverified user should fail")
            .post(tagPath.appending("\(tag.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }

    func testCreateReportWithoutTokenFails() async throws {
        let tag = try await createNewTag()
        let newReport = try getTagReportCreateContent(visibleDetailId: tag.detail.requireID())
        try await tag.detail.$language.load(on: app.db)

        try app
            .describe("Create new report without token should fail")
            .post(tagPath.appending("\(tag.repository.requireID())/reports"))
            .body(newReport)
            .expect(.unauthorized)
            .test()
    }

    func testCreateReportNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let newReport = try getTagReportCreateContent(title: "", visibleDetailId: tag.detail.requireID())
        try await tag.detail.$language.load(on: app.db)

        try app
            .describe("Create new report should require valid title and fail")
            .post(tagPath.appending("\(tag.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testCreateReportNeedsValidReason() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let newReport = try getTagReportCreateContent(reason: "", visibleDetailId: tag.detail.requireID())
        try await tag.detail.$language.load(on: app.db)

        try app
            .describe("Create new report should require valid reason and fail")
            .post(tagPath.appending("\(tag.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testCreateReportNeedsValidVisibleDetailId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let tag2 = try await createNewTag()
        let newReport = try getTagReportCreateContent(visibleDetailId: tag.detail.requireID())
        try await tag.detail.$language.load(on: app.db)

        try app
            .describe("Create new report should require valid visible detail id and fail")
            .post(tagPath.appending("\(tag2.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
