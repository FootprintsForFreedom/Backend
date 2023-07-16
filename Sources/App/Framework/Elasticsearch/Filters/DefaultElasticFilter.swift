import Foundation

/// Represents a default elasticsearch filter.
protocol DefaultElasticFilter {
    /// The name of the default filter.
    static var `default`: String { get }

    /// The filter's name.
    var name: String { get }
}
