import SwiftSMTPVapor
import Vapor

struct UserCreateAccountTemplate: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.Slugs.createAccountSlug.rawValue }
}
