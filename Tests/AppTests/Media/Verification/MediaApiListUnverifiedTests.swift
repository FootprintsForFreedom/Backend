import Fluent
import Spec
import XCTVapor
@testable import App

final class MediaApiListUnverifiedTests: AppTestCase, MediaTest {
    func testSuccessfulListRepositoriesWithUnverifiedModels() async throws {
        let moderatorToken = try await getToken(for: .moderator)

        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let deactivatedLanguage = try await createLanguage(activated: false)

        let userId = try await getUser(role: .user).requireID()

        // Create an unverified media
        let (unverifiedMediaRepository, createdUnverifiedDetail, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        // Create an unverified media for a deactivated language
        let (unverifiedMediaRepositoryForDeactivatedLanguage, _, _) = try await createNewMedia(languageId: deactivatedLanguage.requireID(), userId: userId)
        // Create a verified media
        let (verifiedMediaRepository, createdVerifiedDetail, createdVerifiedFile) = try await createNewMedia(verified: true, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified media
        let _ = try await MediaDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            detailText: "Some invisible detailText",
            source: "What is this?",
            languageId: language.requireID(),
            repositoryId: verifiedMediaRepository.requireID(),
            fileId: createdVerifiedFile.requireID(),
            userId: userId,
            on: self
        )
        // Create a media in the other language
        let (verifiedMediaRepositoryInDifferentLanguage, _, _) = try await createNewMedia(verified: true, languageId: language2.requireID(), userId: userId)

        // Get unverified media count
        let media = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .with(\.$tags.$pivots)
            .all()

        let mediaCount = media.count

        let unverifiedMediaCount = media
            .filter { $0.details.contains { $0.verifiedAt == nil && $0.language.priority != nil } || $0.$tags.pivots.contains { [Status.pending, .deleteRequested].contains($0.status) } }
            .count

        try app
            .describe("List repositories with unverified models should return ok and the repositories")
            .get(mediaPath.appending("unverified/?preferredLanguage=\(language.languageCode)&per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedMediaCount)
                XCTAssertEqual(content.items.map(\.id).uniqued().count, unverifiedMediaCount)
                XCTAssert(content.items.map(\.id).uniqued().count == content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedMediaCount)

                XCTAssert(content.items.contains { $0.id == unverifiedMediaRepository.id })
                if let unverifiedMedia = content.items.first(where: { $0.id == unverifiedMediaRepository.id }) {
                    XCTAssertEqual(unverifiedMedia.id, unverifiedMediaRepository.id)
                    XCTAssertEqual(unverifiedMedia.title, createdUnverifiedDetail.title)
                }

                // contains the verified media repository because it has a second unverified media model
                // here it should also return the verified model in the list for preview to see which media was edited
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepository.id })
                if let verifiedMedia = content.items.first(where: { $0.id == verifiedMediaRepository.id }) {
                    XCTAssertEqual(verifiedMedia.id, verifiedMediaRepository.id)
                    XCTAssertEqual(verifiedMedia.title, createdVerifiedDetail.title)
                }

                XCTAssertFalse(content.items.contains { $0.id == verifiedMediaRepositoryInDifferentLanguage.id })
                XCTAssertFalse(content.items.contains { $0.id == unverifiedMediaRepositoryForDeactivatedLanguage.id })
            }
            .test()
    }

    func testListRepositoriesWithUnverifiedModelsAsUserFails() async throws {
        let userToken = try await getToken(for: .user)

        try app
            .describe("List repositories with unverified models as user should fail")
            .get(mediaPath.appending("unverified"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }

    func testListRepositoriesWithUnverifiedModelsWithoutTokenFails() async throws {
        try app
            .describe("List repositories with unverified without token should fail")
            .get(mediaPath.appending("unverified"))
            .expect(.unauthorized)
            .test()
    }

    func testListUnverifiedDetailsForRepository() async throws {
        let moderatorToken = try await getToken(for: .moderator)

        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let deactivatedLanguage = try await createLanguage(activated: false)

        let userId = try await getUser(role: .user).requireID()

        // Create an unverified media
        let (mediaRepository, createdUnverifiedDetail, createdFile) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        try await createdUnverifiedDetail.$language.load(on: app.db)
        // Create a verified media for the same repository
        let verifiedDetail = try await MediaDetailModel.createWith(
            verified: true,
            title: "Verified Media \(UUID())",
            detailText: "This is text",
            source: "What is this?",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: self
        )
        // Create a second not verified media for the same repository
        let secondCreatedUnverifiedDetail = try await MediaDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            detailText: "Some invisible detailText",
            source: "What is that?",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: self
        )
        try await secondCreatedUnverifiedDetail.$language.load(on: app.db)
        // Create a not verified media for a deactivated language
        let unverifiedDetailForDeactivatedLanguage = try await MediaDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            detailText: "Some invisible detailText",
            source: "What is that?",
            languageId: deactivatedLanguage.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: self
        )
        // Create a second not verified media for the same repository in another language
        let createdUnverifiedDetailInDifferentLanguage = try await MediaDetailModel.createWith(
            verified: false,
            title: "Different Language \(UUID())",
            detailText: "Not visible detailText, other language",
            source: "Hallo, was ist das?",
            languageId: language2.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: self
        )
        try await createdUnverifiedDetailInDifferentLanguage.$language.load(on: app.db)
        // Create a not verified media for another repository
        let (_, unverifiedDetailForDifferentRepository, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)

        // Get unverified and verified media count
        let mediaCount = try await MediaDetailModel
            .query(on: app.db)
            .count()

        let unverifiedMediaForRepositoryCount = try await MediaDetailModel
            .query(on: app.db)
            .filter(\.$verifiedAt == nil)
            .filter(\.$repository.$id == mediaRepository.requireID())
            .join(parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
            .count()

        try app
            .describe("List unverified medias should return ok and unverified models for all languages")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/?per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Repository.ListUnverified>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedMediaForRepositoryCount)
                XCTAssertEqual(content.items.map(\.detailId).uniqued().count, unverifiedMediaForRepositoryCount)
                XCTAssertEqual(content.items.map(\.detailId).uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedMediaForRepositoryCount)

                XCTAssert(content.items.contains { $0.detailId == createdUnverifiedDetail.id })
                if let unverifiedDetail = content.items.first(where: { $0.detailId == createdUnverifiedDetail.id }) {
                    XCTAssertEqual(unverifiedDetail.detailId, createdUnverifiedDetail.id)
                    XCTAssertEqual(unverifiedDetail.title, createdUnverifiedDetail.title)
                    XCTAssertEqual(unverifiedDetail.detailText, createdUnverifiedDetail.detailText)
                    XCTAssertEqual(unverifiedDetail.languageCode, createdUnverifiedDetail.language.languageCode)
                }

                XCTAssertFalse(content.items.contains { $0.detailId == verifiedDetail.id })

                XCTAssert(content.items.contains { $0.detailId == secondCreatedUnverifiedDetail.id })
                if let secondUnverifiedDetail = content.items.first(where: { $0.detailId == secondCreatedUnverifiedDetail.id }) {
                    XCTAssertEqual(secondUnverifiedDetail.detailId, secondCreatedUnverifiedDetail.id)
                    XCTAssertEqual(secondUnverifiedDetail.title, secondCreatedUnverifiedDetail.title)
                    XCTAssertEqual(secondUnverifiedDetail.detailText, secondCreatedUnverifiedDetail.detailText)
                    XCTAssertEqual(secondUnverifiedDetail.languageCode, secondCreatedUnverifiedDetail.language.languageCode)
                }

                XCTAssert(content.items.contains { $0.detailId == createdUnverifiedDetailInDifferentLanguage.id })
                if let unverifiedDetailInDifferentLanguage = content.items.first(where: { $0.detailId == createdUnverifiedDetailInDifferentLanguage.id }) {
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.detailId, createdUnverifiedDetailInDifferentLanguage.id)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.title, createdUnverifiedDetailInDifferentLanguage.title)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.detailText, createdUnverifiedDetailInDifferentLanguage.detailText)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.languageCode, createdUnverifiedDetailInDifferentLanguage.language.languageCode)
                }

                XCTAssertFalse(content.items.contains { $0.detailId == unverifiedDetailForDifferentRepository.id })
                XCTAssertFalse(content.items.contains { $0.detailId == unverifiedDetailForDeactivatedLanguage.id })
            }
            .test()
    }

    func testListUnverifiedDetailsForRepositoryAsUserFails() async throws {
        let userToken = try await getToken(for: .user)

        // Create an unverified media
        let (mediaRepository, _, _) = try await createNewMedia()

        try app
            .describe("List unverified media as user should fail")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }

    func testListUnverifiedDetailsForRepositoryWithoutTokenFails() async throws {
        // Create an unverified media
        let (mediaRepository, _, _) = try await createNewMedia()

        try app
            .describe("List unverified media without token should fail")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/"))
            .expect(.unauthorized)
            .test()
    }
}
