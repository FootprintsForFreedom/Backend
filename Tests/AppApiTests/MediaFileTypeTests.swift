import XCTest
@testable import AppApi

final class MediaFileTypeTests: XCTestCase {
    func testNoDuplicateMimeType() {
        let allMimeTypes = Media.Detail.FileType.allCases.map(\.allowedMimeTypes).flatMap { $0 }
        let duplicateMimeTypes = Dictionary(grouping: allMimeTypes) { $0 }
            .filter { $1.count > 1 }.keys
        XCTAssert(duplicateMimeTypes.isEmpty)
    }
}
