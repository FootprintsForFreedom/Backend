import Fluent
import Foundation

/// Represents an object that can be initialized with just the id.
protocol InitializableById: Codable {
    /// Initialize the object with an id on a database.
    /// - Parameters:
    ///   - id: The object id.
    ///   - db: The database on which to find the associated database model.
    init?(id: UUID?, db: Database) async throws
}
