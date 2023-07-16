import AppApi
import Vapor

extension Request {
    func preferredLanguageCode() throws -> String? {
        try query.decode(Language.Request.PreferredLanguage.self).preferredLanguage
    }

    func allLanguageCodesByPriority() async throws -> [String] {
        try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode(), on: db)
    }
}
