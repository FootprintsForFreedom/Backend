import Fluent
import Spec
import XCTVapor
@testable import App

final class LanguageApiGetTests: AppTestCase, LanguageTest {
    func testSuccessfulListLanguagesReturnsLanguagesByPriority() async throws {
        for _ in 0 ... 4 {
            let language = try await createLanguage()

            // Get languages count
            let languagesCount = try await LanguageModel.query(on: app.db).filter(\.$priority != nil).count()

            try app
                .describe("List languages should return all languages sorted by their priority")
                .get(languagesPath)
                .expect(.ok)
                .expect(.json)
                .expect([Language.Detail.List].self) { content in
                    XCTAssertEqual(languagesCount, content.count)

                    XCTAssert(content.contains { $0.languageCode == language.languageCode })
                    XCTAssertEqual(content.last!.languageCode, language.languageCode)
                }
                .test()
        }
    }

    func testSuccessfulGetLanguage() async throws {
        let language = try await createLanguage()

        try app
            .describe("Get language should return the specified language")
            .get(languagesPath.appending(language.languageCode))
            .expect(.ok)
            .expect(.json)
            .expect(Language.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, language.id)
                XCTAssertEqual(content.languageCode, language.languageCode)
                XCTAssertEqual(content.name, language.name)
                XCTAssertEqual(content.isRTL, language.isRTL)
            }
            .test()
    }

    func testListLanguageDoesNotReturnDeactivatedLanguages() async throws {
        let adminToken = try await getToken(for: .admin)

        var languages = [LanguageModel]()
        for _ in 0 ... 4 {
            let language = try await createLanguage()
            languages.append(language)
        }

        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(languages.last!.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()

        // Get languages count
        let languagesCount = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .count()

        try app
            .describe("List languages should return all languages sorted by their priority except for the deactivated ones")
            .get(languagesPath)
            .expect(.ok)
            .expect(.json)
            .expect([Language.Detail.List].self) { content in
                XCTAssertEqual(languagesCount, content.count)
                XCTAssert(!content.contains { $0.id == languages.last!.id })
            }
            .test()
    }

    func testSuccessfulGetDeactivatedLanguageAsAdmin() async throws {
        let adminToken = try await getToken(for: .admin)
        let language = try await createLanguage()

        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()

        try app
            .describe("Get language should return the specified language")
            .get(languagesPath.appending(language.languageCode))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, language.id)
                XCTAssertEqual(content.languageCode, language.languageCode)
                XCTAssertEqual(content.name, language.name)
                XCTAssertEqual(content.isRTL, language.isRTL)
            }
            .test()
    }

    func testGetDeactivatedLanguageAsModeratorFails() async throws {
        let adminToken = try await getToken(for: .admin)
        let token = try await getToken(for: .moderator)
        let language = try await createLanguage()

        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()

        try app
            .describe("Get deactivated language as moderator should fail")
            .get(languagesPath.appending(language.languageCode))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }

    func testSuccessfulListUnusedLanguages() async throws {
        let adminToken = try await getToken(for: .admin)

        try app
            .describe("Moderator should be able to list unused languages.")
            .get(languagesPath.appending("unused"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect([AppApi.Language.Detail.ListUnused].self) { content in
                // Confirm it does not contain existing language
                XCTAssert(!content.contains { $0.languageCode == "de" })
            }
            .test()
    }

    func testListUnusedLanguagesAsModeratorFails() async throws {
        try app
            .describe("Moderator should be able to list unused languages.")
            .get(languagesPath.appending("unused"))
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .test()
    }

    func testListUnusedLanguagesAsUserFails() async throws {
        let userToken = try await getToken(for: .user, verified: true)

        try app
            .describe("Moderator should be able to list unused languages.")
            .get(languagesPath.appending("unused"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }

    func testListUnusedLanguagesWithoutTokenFails() async throws {
        try app
            .describe("Moderator should be able to list unused languages.")
            .get(languagesPath.appending("unused"))
            .expect(.unauthorized)
            .test()
    }
}
