import Vapor

extension Request {
    /// Asynchronously invoke the first hook function with the given name.
    /// - Parameters:
    ///   - name: The name of the hook function to invoke.
    ///   - args: The hook arguments passed to the hook function.
    /// - Returns: The returned value from the invoked hook function.
    func invokeAsync<ReturnType>(_ name: HookName, args: HookArguments = [:]) async throws -> ReturnType? {
        let ctxArgs = args.merging([HookArgumentName.request: self]) { _, new in new }
        return try await application.invokeAsync(name, args: ctxArgs)
    }

    /// Asynchronously invoke all hook functions with the given name.
    /// - Parameters:
    ///   - name: The name of the hook function to invoke.
    ///   - args: The hook arguments passed to the hook function.
    /// - Returns: An array of the return values of all hook functions with the given name.
    func invokeAllAsync<ReturnType>(_ name: HookName, args: HookArguments = [:]) async throws -> [ReturnType] {
        let ctxArgs = args.merging([HookArgumentName.request: self]) { _, new in new }
        return try await application.invokeAllAsync(name, args: ctxArgs)
    }
}
