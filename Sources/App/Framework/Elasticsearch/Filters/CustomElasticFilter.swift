import Foundation

/// Represents a custom elasticsearch filter.
protocol CustomElasticFilter: DefaultElasticFilter, Equatable {
    /// The json representation of the filter.
    var json: [String: Any] { get }
}
