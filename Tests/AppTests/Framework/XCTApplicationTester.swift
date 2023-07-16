import XCTVapor

public extension XCTApplicationTester {
    @discardableResult func test(
        _ method: HTTPMethod,
        _ path: String,
        headers: HTTPHeaders = [:],
        content: some Content,
        afterResponse: (XCTHTTPResponse) throws -> Void = { _ in }
    ) throws -> XCTApplicationTester {
        try test(method, path, headers: headers, beforeRequest: { req in
            try req.content.encode(content)
        }, afterResponse: afterResponse)
    }
}
