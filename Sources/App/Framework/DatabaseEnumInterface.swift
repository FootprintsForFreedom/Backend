public protocol DatabaseEnumInterface {
    /// The module of the enum model.
    associatedtype Module: ModuleInterface
    /// The identifier of the enum model.
    ///
    /// The usually consists of the model name.
    static var identifier: String { get }
}

public extension DatabaseEnumInterface {
    /// The schema name of the database model.
    ///
    /// The schema usually consists of the module identifier joined with the model identifier.
    static var schema: String { Module.identifier + "_" + identifier }

    static var identifier: String {
        String(describing: self).dropFirst(Module.identifier.count).lowercased() + "s"
    }
}
