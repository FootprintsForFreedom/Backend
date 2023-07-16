import Fluent

/// Represents a model with a title
public protocol Titled where Self: Fluent.Model {
    /// The model's title.
    var title: String { get set }
}
