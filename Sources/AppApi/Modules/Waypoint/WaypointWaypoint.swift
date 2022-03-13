//
//  File.swift
//  
//
//  Created by niklhut on 17.02.22.
//

import Foundation
import DiffMatchPatch

public extension Waypoint {
    enum Waypoint: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Waypoint {
    struct List: Codable {
        public let id: UUID
        public let title: String
        public let location: Waypoint.Location
        
        public init(id: UUID, title: String, location: Waypoint.Location) {
            self.id = id
            self.title = title
            self.location = location
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let title: String
        public let description: String
        public let location: Waypoint.Location
        public let languageCode: String
        public let verified: Bool?
        
        public static func publicDetail(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                location: location,
                languageCode: languageCode
            )
        }
        
        public static func moderatorDetail(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String, verified: Bool) -> Self {
            return .init(
                id: id,
                title: title,
                description: description,
                location: location,
                languageCode: languageCode,
                verified: verified
            )
        }
        
        private init(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String) {
            self.id = id
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
            self.verified = nil
        }
        
        private init(id: UUID, title: String, description: String, location: Waypoint.Location, languageCode: String, verified: Bool) {
            self.id = id
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
            self.verified = verified
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let description: String
        public let location: Waypoint.Location
        public let languageCode: String
        
        public init(title: String, description: String, location: Waypoint.Location, languageCode: String) {
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
        }
    }
    
    struct Update: Codable {
        public let title: String
        public let description: String
        public let location: Waypoint.Location
        public let languageCode: String
        
        public init(title: String, description: String, location: Waypoint.Location, languageCode: String) {
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
        }
    }
    
    struct Patch: Codable {
        public let title: String?
        public let description: String?
        public let location: Waypoint.Location?
        public let languageCode: String
        
        public init(title: String?, description: String?, location: Waypoint.Location?, languageCode: String) {
            self.title = title
            self.description = description
            self.location = location
            self.languageCode = languageCode
        }
    }
}

public extension Waypoint.Waypoint {
    struct DetailChangesRequest: Codable {
        public let from: UUID?
        public let to: UUID?
        
        public init(from: UUID?, to: UUID?) {
            self.from = from
            self.to = to
        }
    }
    
    struct Changes: Codable {
        public let titleDiff: [Diff]
        public let descriptionDiff: [Diff]
        public let oldLocation: Waypoint.Location
        public let newLocation: Waypoint.Location?
        
        public init(titleDiff: [Diff], descriptionDiff: [Diff], oldLocation: Waypoint.Location, newLocation: Waypoint.Location?) {
            self.titleDiff = titleDiff
            self.descriptionDiff = descriptionDiff
            self.oldLocation = oldLocation
            self.newLocation = newLocation
        }
    }
}
