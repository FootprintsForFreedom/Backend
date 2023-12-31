import Queues
import Vapor

/// A job to reload the mmdb from the disk periodically to keep it up to date.
struct ReloadMMDBJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        try context.application.mmdb.loadMMDB()
    }
}
