import Foundation

extension Array {
    /// Groups an array into a dictionary by a certain key.
    /// - Parameter keyForValue: The key which is used to group the array.
    /// - Returns: A dictionary which has the specified key as key and all elements of the array with this key as values.
    func grouped<Key: Hashable>(by keyForValue: (Element) throws -> Key) throws -> [Key: [Element]] {
        try Dictionary(grouping: self, by: keyForValue)
    }
}
