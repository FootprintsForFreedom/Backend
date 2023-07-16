import Fluent
import Vapor

/// Streamlines reporting repositories.
protocol ApiRepositoryReportController:
    ApiRepositoryCreateReportController,
    ApiRepositoryListUnverifiedReportsController,
    ApiRepositoryVerifyReportController
{
    /// Sets up the report routes.
    /// - Parameter routes: The routes on which to setup the report routes.
    func setupReportRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryReportController {
    func setupReportRoutes(_ routes: RoutesBuilder) {
        setupCreateReportRoutes(routes)
        setupListUnverifiedReportsRoutes(routes)
        setupVerifyReportRoutes(routes)
    }
}
