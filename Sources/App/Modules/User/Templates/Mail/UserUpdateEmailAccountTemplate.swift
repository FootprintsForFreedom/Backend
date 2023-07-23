import SwiftSMTPVapor
import Vapor

struct UserUpdateEmailAccountTemplate: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.Slugs.updateEmailSlug.rawValue }
}
