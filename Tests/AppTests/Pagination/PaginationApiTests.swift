import Fluent
import Spec
import XCTVapor
@testable import App

final class PaginationApiTests: AppTestCase, MediaTest, WaypointTest, TagTest {
    enum ModelType {
        case mediaRepository
        case waypointRepository
        case tag
        case tagRepository
    }

    func idFor(_ modelType: ModelType) async throws -> String {
        switch modelType {
        case .mediaRepository:
            return try await createNewMedia().repository.requireID().uuidString
        case .waypointRepository:
            return try await createNewWaypoint().repository.requireID().uuidString
        case .tag:
            return try await createNewTag().detail.requireID().uuidString
        case .tagRepository:
            return try await createNewTag().repository.requireID().uuidString
        }
    }

    func getPaginatedEndpoints() async throws -> [String: [String: Any]?] {
        async let mediaRepositoryId = idFor(.mediaRepository)
        async let waypointRepositoryId = idFor(.waypointRepository)
        async let tagId = idFor(.tag)
        async let tagRepositoryId = idFor(.tagRepository)

        return try await [
            "/api/v1/media": nil,
            "/api/v1/media/search": ["languageCode": "de", "text": "test"],
            "/api/v1/media/unverified": nil,
            "/api/v1/media/\(mediaRepositoryId)/unverified": nil,
            "/api/v1/media/\(mediaRepositoryId)/reports/unverified": nil,
            "/api/v1/media/\(mediaRepositoryId)/tags/unverified": nil,
            "/api/v1/waypoints": nil,
            "/api/v1/waypoints/\(waypointRepositoryId)/media": nil,
            "/api/v1/waypoints/search": ["languageCode": "de", "text": "test"],
            "/api/v1/waypoints/in": ["topLeftLatitude": 5, "topLeftLongitude": 5, "bottomRightLatitude": 0, "bottomRightLongitude": 10],
            "/api/v1/waypoints/unverified": nil,
            "/api/v1/waypoints/\(waypointRepositoryId)/waypoints/unverified": nil,
            "/api/v1/waypoints/\(waypointRepositoryId)/locations/unverified": nil,
            "/api/v1/waypoints/\(waypointRepositoryId)/reports/unverified": nil,
            "/api/v1/waypoints/\(waypointRepositoryId)/tags/unverified": nil,
            "/api/v1/tags": nil,
            "/api/v1/tags/search": ["languageCode": "de", "text": "test"],
            "/api/v1/tags/\(tagId)/media": nil,
            "/api/v1/tags/\(tagId)/waypoints": nil,
            "/api/v1/tags/unverified": nil,
            "/api/v1/tags/\(tagRepositoryId)/unverified": nil,
            "/api/v1/tags/\(tagRepositoryId)/reports/unverified": nil,
            "/api/v1/user/accounts": nil,
            "/api/v1/staticContent": nil,
            "/api/v1/redirects": nil
        ]
    }

    func serialize(_ parameters: [String: Any]?) -> String {
        guard let parameters else { return "" }
        return parameters.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
    }

    func testPaginationPerFieldNeedsValidValue() async throws {
        async let paginatedEndpoints = getPaginatedEndpoints()
        async let token = getToken(for: .admin)

        for endpoint in try await paginatedEndpoints {
            var queryParameters = endpoint.value ?? [:]
            queryParameters["per"] = "hi"
            let serializedParameters = "?\(serialize(queryParameters))"

            try await app
                .describe("Per parameter in page request should be validated")
                .get(endpoint.key.appending(serializedParameters))
                .bearerToken(token)
                .expect(.badRequest)
                .test()
        }
    }

    func testPaginationPageFieldNeedsValidValue() async throws {
        async let paginatedEndpoints = getPaginatedEndpoints()
        async let token = getToken(for: .admin)

        for endpoint in try await paginatedEndpoints {
            var queryParameters = endpoint.value ?? [:]
            queryParameters["page"] = "hi"
            let serializedParameters = "?\(serialize(queryParameters))"

            try await app
                .describe("Per parameter in page request should be validated")
                .get(endpoint.key.appending(serializedParameters))
                .bearerToken(token)
                .expect(.badRequest)
                .test()
        }
    }
}
