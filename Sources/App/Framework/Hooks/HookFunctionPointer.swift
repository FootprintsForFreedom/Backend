/// Class which points towards specific hook functions.
final class HookFunctionPointer<Pointer> {
    /// The name of the hook function.
    var name: HookName
    /// The pointer to the hook function
    var pointer: Pointer
    /// The return type of the hook function
    var returnType: Any.Type

    /// Initialize a hook function pointer with its name, function and return type.
    /// - Parameters:
    ///   - name: The name of the hook function.
    ///   - function: The actual hook function code.
    ///   - returnType: The return type of the hook function.
    init(name: HookName, function: Pointer, returnType: Any.Type) {
        self.name = name
        pointer = function
        self.returnType = returnType
    }
}
