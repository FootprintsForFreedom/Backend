import Fluent
import Queues
import Vapor

/// A job which cleans up soft deleted models after a certain time..
struct CleanupSoftDeletedModelsJob: AsyncScheduledJob {
    /// Cleans up all soft deleted models older than specified in the environment.
    ///
    /// If no lifetime for soft deleted models is set no soft deleted models will be deleted.
    ///
    /// - Parameters:
    ///   - modelType: The type of the model whose soft deleted models are to be deleted.
    ///   - db: The database on which to find and delete the soft deleted models.
    func cleanupSoftDeleted(_ modelType: (some Timestamped).Type, on app: Application) async throws {
        /// Get the soft deleted lifetime or return.
        guard let softDeletedLifetime = Environment.softDeletedLifetime else {
            return
        }
        let dayInSeconds = 60 * 60 * 24

        if modelType is MediaFileModel.Type {
            try await modelType
                .query(on: app.db)
                .withDeleted()
                .filter(\._$deletedAt < Date().addingTimeInterval(TimeInterval(-1 * softDeletedLifetime * dayInSeconds))) // only select models that are older than the specified amount of days
                .all()
                .asyncForEach { mediaFile in
                    guard let mediaFile = mediaFile as? MediaFileModel else { return }
                    try FileStorage.delete(at: mediaFile.absoluteMediaFilePath(app.directory.publicDirectory))
                    try FileStorage.delete(at: mediaFile.absoluteThumbnailFilePath(app.directory.publicDirectory))
                    try await mediaFile.delete(force: true, on: app.db)
                }
        } else {
            /// Query the model type and delete all models which were soft deleted and whose lifetime expired.
            try await modelType
                .query(on: app.db)
                .withDeleted() // also query soft deleted models
                .filter(\._$deletedAt < Date().addingTimeInterval(TimeInterval(-1 * softDeletedLifetime * dayInSeconds))) // only select models that are older than the specified amount of days
                .delete(force: true) // and delete them
        }
    }

    func run(context: QueueContext) async throws {
        /// All model types to cleanup.
        let timestampedTypes: [any Timestamped.Type] = [
            TagRepositoryModel.self,
            TagDetailModel.self,
            TagReportModel.self,
            MediaRepositoryModel.self,
            MediaDetailModel.self,
            MediaFileModel.self,
            MediaReportModel.self,
            WaypointRepositoryModel.self,
            WaypointDetailModel.self,
            WaypointLocationModel.self,
            WaypointReportModel.self,
            StaticContentRepositoryModel.self,
            StaticContentDetailModel.self,
            RedirectModel.self,
        ]

        try await timestampedTypes.asyncForEach { timestampedType in
            try await cleanupSoftDeleted(timestampedType, on: context.application)
        }
    }
}
