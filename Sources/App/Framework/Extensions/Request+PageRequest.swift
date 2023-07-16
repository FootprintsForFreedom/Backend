import Fluent
import Vapor

extension Request {
    var pageRequest: PageRequest {
        get throws {
            let pageRequest = try query.decode(PageRequest.self)
            return PageRequest(page: max(pageRequest.page, 1), per: max(pageRequest.per, 1))
        }
    }
}
