import SwiftSMTP
import Vapor

struct MailDefaults {
    static var sender: Email.Contact {
        let email = Environment.emailAddress
        let name = Environment.appName
        return Email.Contact(name: name, emailAddress: email)
    }
}
