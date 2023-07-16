extension Sequence where Element: Hashable {
    /// Get all unique elements in an array.
    /// - Returns: All unique elements in the array without any duplicates.
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
