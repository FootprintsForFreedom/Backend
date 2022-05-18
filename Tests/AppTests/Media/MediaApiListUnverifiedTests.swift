//
//  MediaApiListUnverifiedTests.swift
//  
//
//  Created by niklhut on 18.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiListUnverifiedTests: AppTestCase, MediaTest {
    let mediaPath = "api/media/"
    
    func testSuccessfulListRepositoriesWithUnverifiedModels() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified media
        let (unverifiedMediaRepository, createdUnverifiedDescription, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        // Create a verified media
        let (verifiedMediaRepository, createdVerifiedDescription, createdVerifiedFile) = try await createNewMedia(verified: true, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified media
        let _ = try await MediaDescriptionModel.createWith(
            verified: false,
            title: "Not visible",
            description: "Some invisible description",
            source: "What is this?",
            languageId: language.requireID(),
            repositoryId: verifiedMediaRepository.requireID(),
            fileId: createdVerifiedFile.requireID(),
            userId: userId,
            on: app.db
        )
        // Create a media in the other language
        let (verifiedMediaRepositoryInDifferentLanguage, _, _) = try await createNewMedia(verified: true, languageId: language2.requireID(), userId: userId)
        
        // Get unverified media count
        let media = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$media) { $0.with(\.$language) }
            .all()
        
        let mediaCount = media.count
        
        let verifiedMediaCount = media
            .filter { $0.media.contains { !$0.verified && $0.language.priority != nil } }
            .count
        
        try app
            .describe("List repositories with unverified models should return ok and the repositories")
            .get(mediaPath.appending("unverified/?preferredLanguage=\(language.languageCode)&per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Media.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, verifiedMediaCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, verifiedMediaCount)
                XCTAssert(content.items.map { $0.id }.uniqued().count == content.items.count)
                XCTAssertEqual(content.metadata.total, verifiedMediaCount)
                
                XCTAssert(content.items.contains { $0.id == unverifiedMediaRepository.id })
                if let unverifiedMedia = content.items.first(where: { $0.id == unverifiedMediaRepository.id }) {
                    XCTAssertEqual(unverifiedMedia.id, unverifiedMediaRepository.id)
                    XCTAssertEqual(unverifiedMedia.title, createdUnverifiedDescription.title)
                }
                
                
                // contains the verified media repository because it has a second unverified media model
                // here it should also return the verified model in the list for preview to see which media was edited
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepository.id })
                if let verifiedMedia = content.items.first(where: { $0.id == verifiedMediaRepository.id }) {
                    XCTAssertEqual(verifiedMedia.id, verifiedMediaRepository.id)
                    XCTAssertEqual(verifiedMedia.title, createdVerifiedDescription.title)
                }
                
                XCTAssertFalse(content.items.contains { $0.id == verifiedMediaRepositoryInDifferentLanguage.id })
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
    
    func testListUnverifiedDescriptionsForRepository() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified media
        let (mediaRepository, createdUnverifiedDescription, createdFile) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        try await createdUnverifiedDescription.$language.load(on: app.db)
        // Create a verified media for the same repository
        let verifiedDescription = try await MediaDescriptionModel.createWith(
            verified: true,
            title: "Verified Media",
            description: "This is text",
            source: "What is this?",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: app.db
        )
        // Create a second not verified media for the same repository
        let secondCreatedUnverifiedDescription = try await MediaDescriptionModel.createWith(
            verified: false,
            title: "Not visible",
            description: "Some invisible description",
            source: "What is that?",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: app.db
        )
        try await secondCreatedUnverifiedDescription.$language.load(on: app.db)
        // Create a second not verified media for the same repository in another language
        let createdUnverifiedDescriptionInDifferentLanguage = try await MediaDescriptionModel.createWith(
            verified: false,
            title: "Different Language",
            description: "Not visible description, other language",
            source: "Hallo, was ist das?",
            languageId: language2.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: app.db
        )
        try await createdUnverifiedDescriptionInDifferentLanguage.$language.load(on: app.db)
        // Create a not verified media for another repository
        let (_, unverifiedDescriptionForDifferentRepository, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)

        // Get unverified and verified media count
        let mediaCount = try await MediaDescriptionModel
            .query(on: app.db)
            .count()

        let unverifiedMediaForRepositoryCount = try await MediaDescriptionModel
            .query(on: app.db)
            .filter(\.$verified == false)
            .filter(\.$mediaRepository.$id == mediaRepository.requireID())
            .count()

        try app
            .describe("List unverified medias should return ok and unverified models for all languages")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/?per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Repository.ListUnverified>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedMediaForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.modelId }.uniqued().count, unverifiedMediaForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.modelId }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedMediaForRepositoryCount)

                XCTAssert(content.items.contains { $0.modelId == createdUnverifiedDescription.id })
                if let unverifiedDescription = content.items.first(where: { $0.modelId == createdUnverifiedDescription.id }) {
                    XCTAssertEqual(unverifiedDescription.modelId, createdUnverifiedDescription.id)
                    XCTAssertEqual(unverifiedDescription.title, createdUnverifiedDescription.title)
                    XCTAssertEqual(unverifiedDescription.description, createdUnverifiedDescription.description)
                    XCTAssertEqual(unverifiedDescription.languageCode, createdUnverifiedDescription.language.languageCode)
                }

                XCTAssertFalse(content.items.contains { $0.modelId == verifiedDescription.id })

                XCTAssert(content.items.contains { $0.modelId == secondCreatedUnverifiedDescription.id })
                if let secondUnverifiedDescription = content.items.first(where: { $0.modelId == secondCreatedUnverifiedDescription.id }) {
                    XCTAssertEqual(secondUnverifiedDescription.modelId, secondCreatedUnverifiedDescription.id)
                    XCTAssertEqual(secondUnverifiedDescription.title, secondCreatedUnverifiedDescription.title)
                    XCTAssertEqual(secondUnverifiedDescription.description, secondCreatedUnverifiedDescription.description)
                    XCTAssertEqual(secondUnverifiedDescription.languageCode, secondCreatedUnverifiedDescription.language.languageCode)
                }

                XCTAssert(content.items.contains { $0.modelId == createdUnverifiedDescriptionInDifferentLanguage.id })
                if let unverifiedDescriptionInDifferentLanguage = content.items.first(where: { $0.modelId == createdUnverifiedDescriptionInDifferentLanguage.id }) {
                    XCTAssertEqual(unverifiedDescriptionInDifferentLanguage.modelId, createdUnverifiedDescriptionInDifferentLanguage.id)
                    XCTAssertEqual(unverifiedDescriptionInDifferentLanguage.title, createdUnverifiedDescriptionInDifferentLanguage.title)
                    XCTAssertEqual(unverifiedDescriptionInDifferentLanguage.description, createdUnverifiedDescriptionInDifferentLanguage.description)
                    XCTAssertEqual(unverifiedDescriptionInDifferentLanguage.languageCode, createdUnverifiedDescriptionInDifferentLanguage.language.languageCode)
                }

                XCTAssertFalse(content.items.contains { $0.modelId == unverifiedDescriptionForDifferentRepository.id })
            }
            .test()
    }
    
    func testListUnverifiedDescriptionsForRepositoryAsUserFails() async throws {
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
    
    func testListUnverifiedDescriptionsForRepositoryWithoutTokenFails() async throws {
        // Create an unverified media
        let (mediaRepository, _, _) = try await createNewMedia()
        
        try app
            .describe("List unverified media without token should fail")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/"))
            .expect(.unauthorized)
            .test()
    }
}
