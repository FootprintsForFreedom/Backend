import MMDB
import Vapor

extension Application {
    var mmdb: MMDBObject {
        .init(application: self)
    }

    struct MMDBObject {
        let application: Application

        struct Key: StorageKey {
            typealias Value = MMDB
        }

        var mmdb: MMDB {
            if application.storage[Key.self] == nil {
                try! loadMMDB()
            }
            return application.storage[Key.self]!
        }

        func loadMMDB() throws {
            let url = URL(fileURLWithPath: application.directory.resourcesDirectory).appendingPathComponent(Environment.mmdbPath)
            application.storage[Key.self] = try! .init(from: url)
        }
    }
}

extension Request {
    var mmdb: MMDB {
        application.mmdb.mmdb
    }
}
