import SwiftSMTPVapor
import Vapor

struct UserRequestPasswordResetMail: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.Slugs.passwordResetSlug.rawValue }
}
