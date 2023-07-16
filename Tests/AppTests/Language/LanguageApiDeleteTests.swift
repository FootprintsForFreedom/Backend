import Fluent
import Spec
import XCTVapor
@testable import App

final class LanguageApiDeleteTests: AppTestCase, LanguageTest {
    func testDeleteLanguageFails() async throws {
        let token = try await getToken(for: .superAdmin)
        let language = try await createLanguage()

        try app
            .describe("Delete language always fails succeeds")
            .delete(languagesPath.appending(language.requireID().uuidString))
            .bearerToken(token)
            .expect(.internalServerError)
            .test()
    }
}
