import AppApi
import Fluent
import Vapor

extension AppApi.Page: AsyncRequestDecodable, AsyncResponseEncodable, RequestDecodable, ResponseEncodable, Content where T: Codable { }

extension AppApi.Page {
    static func from(_ page: Fluent.Page<T>) -> Self {
        .init(items: page.items, metadata: .from(page.metadata))
    }
}

extension AppApi.PageMetadata {
    static func from(_ pageMetadata: Fluent.PageMetadata) -> Self {
        .init(page: pageMetadata.page, per: pageMetadata.per, total: pageMetadata.total)
    }
}
