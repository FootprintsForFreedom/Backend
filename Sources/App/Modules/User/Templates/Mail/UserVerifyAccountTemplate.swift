import SwiftSMTPVapor
import Vapor

struct UserVerifyAccountTemplate: MailTemplateRepresentable {
    static var staticContentSlug: String { StaticContentMigrations.seed.verifyAccountSlug }
}
