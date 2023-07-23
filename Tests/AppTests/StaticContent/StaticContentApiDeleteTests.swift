import Fluent
import Spec
import XCTVapor
@testable import App

final class StaticContentApiDeleteTests: AppTestCase, StaticContentTest {
    func testSuccessfulDeleteUnverifiedStaticContentAsAdmin() async throws {
        // Get original staticContent count
        let staticContentCount = try await StaticContentRepositoryModel.query(on: app.db).count()

        let (staticContentRepository, _) = try await createNewStaticContent()
        let adminToken = try await getToken(for: .admin)

        try app
            .describe("An admin should be able to delete an unverified staticContent")
            .delete(staticContentPath.appending(staticContentRepository.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.noContent)
            .test()

        // New staticContent count should be one less than original staticContent count
        let newStaticContentCount = try await StaticContentRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newStaticContentCount, staticContentCount)
    }

    func testSuccessfulDeleteVerifiedStaticContentAsAdmin() async throws {
        // Get original staticContent count
        let staticContentCount = try await StaticContentRepositoryModel.query(on: app.db).count()

        let (staticContentRepository, _) = try await createNewStaticContent()
        let adminToken = try await getToken(for: .admin)

        try app
            .describe("An admin should be able to delete an unverified staticContent")
            .delete(staticContentPath.appending(staticContentRepository.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.noContent)
            .test()

        // New staticContent count should be one less than original staticContent count
        let newStaticContentCount = try await StaticContentRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newStaticContentCount, staticContentCount)
    }

    func testDeleteStaticContentRepositoryDeletesDetails() async throws {
        // Get original staticContent count
        let staticContentCount = try await StaticContentRepositoryModel.query(on: app.db).count()
        let detailCount = try await StaticContentDetailModel.query(on: app.db).count()

        let (staticContentRepository, _) = try await createNewStaticContent()
        let adminToken = try await getToken(for: .admin)

        try app
            .describe("An admin should be able to delete an unverified staticContent")
            .delete(staticContentPath.appending(staticContentRepository.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.noContent)
            .test()

        // New staticContent count should be one less than original staticContent count
        let newStaticContentCount = try await StaticContentRepositoryModel.query(on: app.db).count()
        let newDetailCount = try await StaticContentDetailModel.query(on: app.db).count()
        XCTAssertEqual(newStaticContentCount, staticContentCount)
        XCTAssertEqual(newDetailCount, detailCount)
    }

    func testDeleteUnverifiedStaticContentAsCreatorFails() async throws {
        let userToken = try await getToken(for: .user)
        let (staticContentRepository, _) = try await createNewStaticContent()

        try app
            .describe("A user should not be able to delete a staticContent")
            .delete(staticContentPath.appending(staticContentRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }

    func testDeleteUnverifiedStaticContentAsUserFails() async throws {
        let (staticContentRepository, _) = try await createNewStaticContent()
        let userToken = try await getToken(for: .user)

        try app
            .describe("A user should not be able to delete a staticContent")
            .delete(staticContentPath.appending(staticContentRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }

    func testDeleteStaticContentWithoutTokenFails() async throws {
        let (staticContentRepository, _) = try await createNewStaticContent()

        try app
            .describe("Delete staticContent without token fails")
            .delete(staticContentPath.appending(staticContentRepository.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }

    func testDeleteNonExistingStaticContentFails() async throws {
        let adminToken = try await getToken(for: .admin)

        try app
            .describe("Delete nonexistent staticContent fails")
            .delete(staticContentPath.appending(UUID().uuidString))
            .bearerToken(adminToken)
            .expect(.notFound)
            .test()
    }

    func testDeleteCriticalStaticContentFails() async throws {
        let adminToken = try await getToken(for: .admin)

        for slug in StaticContentMigrations.seed.Slugs.allCases {
            guard let staticContentRepository = try await StaticContentRepositoryModel
                .query(on: app.db)
                .filter(\.$slug == slug.rawValue)
                .first()
            else {
                XCTFail("static content not found")
                return
            }

            try app
                .describe("Delete critical staticContent fails")
                .delete(staticContentPath.appending(staticContentRepository.requireID().uuidString))
                .bearerToken(adminToken)
                .expect(.forbidden)
                .test()
        }
    }
}
