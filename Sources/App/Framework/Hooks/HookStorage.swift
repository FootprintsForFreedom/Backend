/// Stores all synchronous and asynchronous hooks.
final class HookStorage {
    /// The pointers to the synchronous hook functions.
    var pointers: [HookFunctionPointer<HookFunction>]
    /// The pointers to the asynchronous hook functions.
    var asyncPointers: [HookFunctionPointer<AsyncHookFunction>]

    init() {
        pointers = []
        asyncPointers = []
    }
}
