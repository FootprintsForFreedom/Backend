//
//  MediaApiUpdateTests.swift
//  
//
//  Created by niklhut on 16.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Media.Detail.Update: Content { }

final class MediaApiUpdateTests: AppTestCase, MediaTest {
    private func getMediaUpdateContent(
        title: String = "New Meidia Title \(UUID())",
        updatedTitle: String = "Updated Title",
        detailText: String = "New Media Description",
        updatedDetailText: String = "Updated Description",
        source: String = "New Media Source",
        updatedSource: String = "Updated Media Soruce",
        languageId: UUID? = nil,
        updateLanguageCode: String? = nil,
        waypointId: UUID? = nil,
        setMediaIdForFile: Bool = true,
        status: Status = .pending
    ) async throws -> (mediaRepository: MediaRepositoryModel, createdMediaDetail: MediaDetailModel, createdMediaFile: MediaFileModel, updateContent: Media.Detail.Update) {
        let (repository, detail, file) = try await createNewMedia(
            title: title,
            detailText: detailText,
            source: source,
            status: status,
            waypointId: waypointId,
            languageId: languageId
        )
        
        if updateLanguageCode == nil {
            try await detail.$language.load(on: app.db)
        }
        let updateContent = try Media.Detail.Update(
            title: updatedTitle,
            detailText: updatedDetailText,
            source: updatedSource,
            languageCode: updateLanguageCode ?? detail.language.languageCode,
            mediaIdForFile: setMediaIdForFile ? detail.requireID() : nil
        )
        return (repository, detail, file, updateContent)
    }
    
    struct TestFile {
        let mimeType: String
        let filename: String
        let fileExtension: String
    }
    
    func testSuccessfulUpdateMedia() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, file, updateContent) = try await getMediaUpdateContent(status: .verified)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media should return ok")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertNotEqual(content.slug, updateContent.title.slugify())
                XCTAssertContains(content.slug, updateContent.title.slugify())
                XCTAssertEqual(content.detailText, updateContent.detailText)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.mediaDirectory)
                XCTAssertNil(content.status)
            }
            .test()
        
        // Test the new media model was created correctly
        let newMediaModel = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newMediaModel.id)
        XCTAssertEqual(newMediaModel.status, .pending)
    }
    
    func testSuccessfulUpdateMediaWithFile() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, file, updateContent) = try await getMediaUpdateContent(setMediaIdForFile: false, status: .verified)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        let newFile = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: newFile.filename, withExtension: newFile.fileExtension)
        
        try app
            .describe("Patch media file should return ok")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", newFile.mimeType)
            .bearerToken(token)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertNotEqual(content.slug, updateContent.title.slugify())
                XCTAssertContains(content.slug, updateContent.title.slugify())
                XCTAssertEqual(content.detailText, updateContent.detailText)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
                XCTAssertNotEqual(content.filePath, file.mediaDirectory)
                XCTAssertNil(content.status)
            }
            .test()
        
        // Test the new media model was created correctly
        let newMediaModel = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newMediaModel.id)
        XCTAssertEqual(newMediaModel.status, .pending)
    }
    
    func testSucessfulUpdateWithNewLanguage() async throws {
        let token = try await getToken(for: .user, verified: true)
        let secondLanguage = try await createLanguage(languageCode: UUID().uuidString, name: UUID().uuidString, isRTL: false)
        let (repository, _, file, updateContent) = try await getMediaUpdateContent(updateLanguageCode: secondLanguage.languageCode, status: .verified)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with new language should return ok")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.detailText, updateContent.detailText)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.mediaDirectory)
                XCTAssertNil(content.status)
            }
            .test()
        
        // Test the new media model was created correctly
        let newMediaModel = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newMediaModel.id)
        XCTAssertEqual(newMediaModel.status, .pending)
    }
    
    func testUpdateMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(status: .verified)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media as unverified user should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateMediaWithoutTokenFails() async throws {
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(status: .verified)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media as unverified user should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateMediaNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(updatedTitle: "", status: .verified)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with empty title should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateMediaNeedsValidDetailText() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(updatedDetailText: "", status: .verified)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with empty detailText should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateMediaNeedsValidSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(updatedSource: "", status: .verified)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with empty source should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateMediaNeedsValidContentType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(setMediaIdForFile: false, status: .verified)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        let newFile = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: newFile.filename, withExtension: newFile.fileExtension)
        
        try app
            .describe("Update media should need valid content type or fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", "hallo/test")
            .bearerToken(token)
            .expect(.unsupportedMediaType)
            .test()
    }
    
    func testUpdateMediaNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository1, _, _, updateContent1) = try await getMediaUpdateContent(updateLanguageCode: "", status: .verified)
        let query1 = try URLEncodedFormEncoder().encode(updateContent1)
        let (repository2, _, _, updateContent2) = try await getMediaUpdateContent(updateLanguageCode: "hi", status: .verified)
        let query2 = try URLEncodedFormEncoder().encode(updateContent2)
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(mediaPath.appending("\(repository1.requireID().uuidString)/?\(query1)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(mediaPath.appending("\(repository2.requireID().uuidString)/?\(query2)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
