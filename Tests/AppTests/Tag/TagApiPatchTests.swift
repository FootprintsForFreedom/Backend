import Fluent
import Spec
import XCTVapor
@testable import App

extension Tag.Detail.Patch: Content { }

final class TagApiPatchTests: AppTestCase, TagTest {
    private func getTagPatchContent(
        title: String = "New Tag title \(UUID())",
        patchedTitle: String? = nil,
        keywords: [String] = (1 ... 5).map { _ in String(Int.random(in: 10 ... 100)) }, // array with 5 random numbers between 10 and 100
        patchedKeywords: [String]? = nil,
        verified: Bool = false,
        languageId: UUID? = nil
    ) async throws -> (repository: TagRepositoryModel, detail: TagDetailModel, patchContent: Tag.Detail.Patch) {
        let (repository, detail) = try await createNewTag(
            title: title,
            keywords: keywords,
            verified: verified,
            languageId: languageId
        )

        let patchContent = try Tag.Detail.Patch(
            title: patchedTitle,
            keywords: patchedKeywords,
            idForTagDetailToPatch: detail.requireID()
        )
        return (repository, detail, patchContent)
    }

    func testSuccessfulPatchTagTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, patchContent) = try await getTagPatchContent(patchedTitle: "The patched title", verified: true)
        try await detail.$language.load(on: app.db)

        try app
            .describe("Patch tag title should return ok")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertNotEqual(content.slug, patchContent.title!.slugify())
                XCTAssertContains(content.slug, patchContent.title!.slugify())
                XCTAssertEqual(content.keywords, detail.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }

    func testSuccessfulPatchTagTitleWithDuplicateTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let title = "My new title \(UUID())"
        let (repository, detail, patchContent) = try await getTagPatchContent(title: title, patchedTitle: title, verified: true)
        try await detail.$language.load(on: app.db)

        try app
            .describe("Patch tag title should return ok")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertNotEqual(content.slug, patchContent.title!.slugify())
                XCTAssertContains(content.slug, patchContent.title!.slugify())
                XCTAssertEqual(content.keywords, detail.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }

    func testSuccessfulPatchTagKeywords() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, patchContent) = try await getTagPatchContent(patchedKeywords: (1 ... 5).map { _ in String(Int.random(in: 10 ... 100)) }, verified: true)
        try await detail.$language.load(on: app.db)

        try app
            .describe("Patch tag keywords should return ok")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertNotEqual(content.slug, detail.title.slugify())
                XCTAssertContains(content.slug, detail.title.slugify())
                XCTAssertEqual(content.keywords, patchContent.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }

    func testEmptyPatchTagFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, patchContent) = try await getTagPatchContent(verified: true)

        try app
            .describe("Patch tag with empty body should fail")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchTagWithIdFromOtherRepositoryFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _) = try await createNewTag()
        let (_, _, patchContent) = try await getTagPatchContent(patchedTitle: UUID().uuidString, verified: true)

        try app
            .describe("Patch tag with id from other repository should fail")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchTagNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, patchContent) = try await getTagPatchContent(patchedTitle: "", verified: true)

        try app
            .describe("Patch tag title should require valid title")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchTagNeedsValidKeywords() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, patchContent) = try await getTagPatchContent(patchedKeywords: [String](), verified: true)

        try app
            .describe("Patch tag title should require valid keywords")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()

        let (repository2, _, patchContent2) = try await getTagPatchContent(patchedKeywords: [""], verified: true)

        try app
            .describe("Patch tag title should require valid keywords")
            .patch(tagPath.appending(repository2.requireID().uuidString))
            .body(patchContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchTagIgnoresEmptyKeywords() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, patchContent) = try await getTagPatchContent(patchedKeywords: ["hallo", "test", "", "\n", "was ist das", " "], verified: true)
        try await detail.$language.load(on: app.db)

        try app
            .describe("Patch tag keywords should ignore invalid keywords")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertNotEqual(content.keywords, patchContent.keywords)
                XCTAssertEqual(content.keywords, patchContent.keywords!.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }

    func testPatchTagNeedsValidIdForTagToPatch() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _) = try await getTagPatchContent(verified: true)
        let patchContent = Tag.Detail.Patch(title: "New Title", keywords: nil, idForTagDetailToPatch: UUID())

        try app
            .describe("Patch tag title should require valid id for tag to patch")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }

    func testPatchTagAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let (repository, _, patchContent) = try await getTagPatchContent(patchedTitle: "The patched title", verified: true)

        try app
            .describe("Patch tag title should return ok")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }

    func testPatchTagWithoutTokenFails() async throws {
        let (repository, _, patchContent) = try await getTagPatchContent(patchedTitle: "The patched title", verified: true)

        try app
            .describe("Patch tag title should return ok")
            .patch(tagPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .expect(.unauthorized)
            .test()
    }
}
