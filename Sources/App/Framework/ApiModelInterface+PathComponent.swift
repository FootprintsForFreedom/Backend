import AppApi
import Vapor

extension ApiModelInterface {
    /// The path id component for the model.
    ///
    /// The path id component usually represents the path id key with a leading colon.
    static var pathIdComponent: PathComponent { .init(stringLiteral: ":" + pathIdKey) }
}
