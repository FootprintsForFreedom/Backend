import Fluent
import Vapor

extension Request {
    var pageRequest: PageRequest {
        get throws {
            guard let pageRequest = try? query.decode(PageRequest.self) else {
                throw Abort(.badRequest, reason: #"Could not decode page request. Make sure "per" and "page" are integers."#)
            }
            return PageRequest(page: max(pageRequest.page, 1), per: max(pageRequest.per, 1))
        }
    }
}
