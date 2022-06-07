//
//  MediaDetail.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Foundation

public extension Media {
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.Media
    }
}

public extension Media.Detail {
    struct List: Codable {
        public let id: UUID
        public let title: String
        public let slug: String
        public let group: Group
        
        public init(id: UUID, title: String, slug: String, group: Group) {
            self.id = id
            self.title = title
            self.slug = slug
            self.group = group
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let languageCode: String
        public let title: String
        public let slug: String
        public let detailText: String
        public let source: String
        public let group: Group
        public let filePath: String
        public let tags: [Tag.Detail.List]
        public let status: Status?
        public let detailId: UUID?
        
        public static func publicDetail(id: UUID, languageCode: String, title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List]) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                title: title,
                slug: slug,
                detailText: detailText,
                source: source,
                group: group,
                filePath: filePath,
                tags: tags
            )
        }
        
        public static func moderatorDetail(id: UUID, languageCode: String, title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List], status: Status, detailId: UUID) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                title: title,
                slug: slug,
                detailText: detailText,
                source: source,
                group: group,
                filePath: filePath,
                tags: tags,
                status: status,
                detailId: detailId
            )
        }
        
        private init(id: UUID, languageCode: String, title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List]) {
            self.id = id
            self.languageCode = languageCode
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.source = source
            self.group = group
            self.filePath = filePath
            self.tags = tags
            self.status = nil
            self.detailId = nil
        }
        
        private init(id: UUID, languageCode: String, title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List], status: Status, detailId: UUID) {
            self.id = id
            self.languageCode = languageCode
            self.title = title
            self.slug = slug
            self.detailText = detailText
            self.source = source
            self.group = group
            self.filePath = filePath
            self.tags = tags
            self.status = status
            self.detailId = detailId
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let detailText: String
        public let source: String
        public let languageCode: String
        public let waypointId: UUID
        
        public init(title: String, detailText: String, source: String, languageCode: String, waypointId: UUID) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.languageCode = languageCode
            self.waypointId = waypointId
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let detailText: String
        public let source: String
        public let languageCode: String
        public let mediaIdForFile: UUID?
        
        public init(title: String, detailText: String, source: String, languageCode: String, mediaIdForFile: UUID?) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.languageCode = languageCode
            self.mediaIdForFile = mediaIdForFile
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let detailText: String?
        public let source: String?
        public let idForMediaToPatch: UUID
        
        public init(title: String?, detailText: String?, source: String?, idForMediaToPatch: UUID) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.idForMediaToPatch = idForMediaToPatch
        }
    }
}
