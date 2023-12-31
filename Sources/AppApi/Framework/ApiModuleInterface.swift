/// An interface for api modules.
public protocol ApiModuleInterface {
    /// The module's path key.
    static var pathKey: String { get }
}

public extension ApiModuleInterface {
    static var pathKey: String { String(describing: self).lowercased() }
}
