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
    /// Used to list media objects.
    struct List: Codable {
        /// Id uniquely identifying the media repository.
        public let id: UUID
        /// The media title.
        public let title: String
        /// The slug uniquely identifying the media.
        public let slug: String
        /// The group of the media file.
        public let group: Group
        
        /// Creates a media list object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the media repository.
        ///   - title: The media title.
        ///   - slug: The slug uniquely identifying the media.
        ///   - group: The group of the media file.
        public init(id: UUID, title: String, slug: String, group: Group) {
            self.id = id
            self.title = title
            self.slug = slug
            self.group = group
        }
    }
    
    /// Used to detail media objects.
    struct Detail: Codable {
        /// Id uniquely identifying the media repository.
        public let id: UUID
        /// The language code for the media title, description and source.
        public let languageCode: String
        /// All language codes available for this media repository.
        public let availableLanguageCodes: [String]
        /// The media title.
        public let title: String
        /// The slug uniquely identifying the media.
        public let slug: String
        /// The detail text describing the media.
        public let detailText: String
        /// The source of the media and/or copyright information.
        public let source: String
        /// The group of the media file.
        public let group: Group
        /// The relative path at which to find the media file.
        public let filePath: String
        /// The tags connected with this media.
        public let tags: [Tag.Detail.List]
        /// The status of the media.
        public let status: Status?
        /// Id uniquely identifying the media detail object.
        public let detailId: UUID?
        
        /// Creates a media detail object for everyone.
        /// - Parameters:
        ///   - id: Id uniquely identifying the media repository.
        ///   - languageCode: The language code for the media title, description and source.
        ///   - availableLanguageCodes: All language codes available for this media repository.
        ///   - title: The media title.
        ///   - slug: The slug uniquely identifying the media.
        ///   - detailText: The detail text describing the media.
        ///   - source: The source of the media and/or copyright information.
        ///   - group: The group of the media file.
        ///   - filePath: The relative path at which to find the media file.
        ///   - tags: The tags connected with this media.
        /// - Returns: A media detail object.
        public static func publicDetail(id: UUID, languageCode: String, availableLanguageCodes: [String], title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List]) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
                title: title,
                slug: slug,
                detailText: detailText,
                source: source,
                group: group,
                filePath: filePath,
                tags: tags
            )
        }
        
        /// Creates a media detail object for moderators.
        /// - Parameters:
        ///   - id: Id uniquely identifying the media repository.
        ///   - languageCode: The language code for the media title, description and source.
        ///   - availableLanguageCodes: All language codes available for this media repository.
        ///   - title: The media title.
        ///   - slug: The slug uniquely identifying the media.
        ///   - detailText: The detail text describing the media.
        ///   - source: The source of the media and/or copyright information.
        ///   - group: The group of the media file.
        ///   - filePath: The relative path at which to find the media file.
        ///   - tags: The tags connected with this media.
        ///   - status: The status of the media
        ///   - detailId: Id uniquely identifying the media detail object.
        /// - Returns: A media detail object.
        public static func moderatorDetail(id: UUID, languageCode: String, availableLanguageCodes: [String], title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List], status: Status, detailId: UUID) -> Self {
            return .init(
                id: id,
                languageCode: languageCode,
                availableLanguageCodes: availableLanguageCodes,
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
        
        /// Creates a media detail object for everyone.
        /// - Parameters:
        ///   - id: Id uniquely identifying the media repository.
        ///   - languageCode: The language code for the media title, description and source.
        ///   - availableLanguageCodes: All language codes available for this media repository.
        ///   - title: The media title.
        ///   - slug: The slug uniquely identifying the media.
        ///   - detailText: The detail text describing the media.
        ///   - source: The source of the media and/or copyright information.
        ///   - group: The group of the media file.
        ///   - filePath: The relative path at which to find the media file.
        ///   - tags: The tags connected with this media.
        private init(id: UUID, languageCode: String, availableLanguageCodes: [String], title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List]) {
            self.id = id
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
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
        
        /// Creates a media detail object for moderators.
        /// - Parameters:
        ///   - id: Id uniquely identifying the media repository.
        ///   - languageCode: The language code for the media title, description and source.
        ///   - availableLanguageCodes: All language codes available for this media repository.
        ///   - title: The media title.
        ///   - slug: The slug uniquely identifying the media.
        ///   - detailText: The detail text describing the media.
        ///   - source: The source of the media and/or copyright information.
        ///   - group: The group of the media file.
        ///   - filePath: The relative path at which to find the media file.
        ///   - tags: The tags connected with this media.
        ///   - status: The status of the media
        ///   - detailId: Id uniquely identifying the media detail object.
        private init(id: UUID, languageCode: String, availableLanguageCodes: [String], title: String, slug: String, detailText: String, source: String, group: Group, filePath: String, tags: [Tag.Detail.List], status: Status, detailId: UUID) {
            self.id = id
            self.languageCode = languageCode
            self.availableLanguageCodes = availableLanguageCodes
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
    
    /// Used to create media objects.
    struct Create: Codable {
        /// The media title.
        public let title: String
        /// The detail text describing the media.
        public let detailText: String
        /// The source of the media and/or copyright information.
        public let source: String
        /// The language code for the media title, description and source.
        public let languageCode: String
        /// The id for the waypoint to which the media belongs.
        public let waypointId: UUID
        
        /// Creates a media create object.
        /// - Parameters:
        ///   - title: The media title.
        ///   - detailText: The detail text describing the media.
        ///   - source: The source of the media and/or copyright information.
        ///   - languageCode: The language code for the media title, description and source.
        ///   - waypointId: The id for the waypoint to which the media belongs.
        public init(title: String, detailText: String, source: String, languageCode: String, waypointId: UUID) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.languageCode = languageCode
            self.waypointId = waypointId
        }
    }
    
    /// Used to update media objects.
    struct Update: Codable {
        /// The media title.
        public let title: String
        /// The detail text describing the media.
        public let detailText: String
        /// The source of the media and/or copyright information.
        public let source: String
        /// The language code for the media title, description and source.
        public let languageCode: String
        /// The id of an existing media. The updated media will have the same file as this media.
        public let mediaIdForFile: UUID?
        
        /// Creates a media update object.
        /// - Parameters:
        ///   - title: The media title.
        ///   - detailText: The detail text describing the media.
        ///   - source: The source of the media and/or copyright information.
        ///   - languageCode: The language code for the media title, description and source.
        ///   - mediaIdForFile: The id of an existing media. The updated media will have the same file as this media.
        public init(title: String, detailText: String, source: String, languageCode: String, mediaIdForFile: UUID?) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.languageCode = languageCode
            self.mediaIdForFile = mediaIdForFile
        }
    }
    
    /// Used to patch media objects.
    struct Patch: Codable {
        /// The media title.
        public let title: String?
        /// The detail text describing the media.
        public let detailText: String?
        /// The source of the media and/or copyright information.
        public let source: String?
        /// The id of an existing media. All parameters not set in this request will be taken from this media.
        public let idForMediaToPatch: UUID
        
        /// Creates a media patch object.
        /// - Parameters:
        ///   - title: The media title.
        ///   - detailText: The detail text describing the media.
        ///   - source: The source of the media and/or copyright information.
        ///   - idForMediaToPatch: The id of an existing media. All parameters not set in this request will be taken from this media.
        public init(title: String?, detailText: String?, source: String?, idForMediaToPatch: UUID) {
            self.title = title
            self.detailText = detailText
            self.source = source
            self.idForMediaToPatch = idForMediaToPatch
        }
    }
}
