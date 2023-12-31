import AppApi
import Fluent
import Vapor

extension Tag.Detail.Detail: InitializableById {
    init?(id: UUID?, db: Database) async throws {
        guard let id, let detail = try await TagDetailModel.find(id, on: db) else {
            return nil
        }
        let repository = try await detail.$repository.get(on: db)
        try await detail.$language.load(on: db)
        self = try await .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
            keywords: detail.keywords,
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(db),
            detailId: detail.requireID()
        )
    }
}

extension TagApiController: ApiRepositoryReportController {
    typealias ReportCreateObject = Report.Create
    typealias ReportDetailObject = Report.Detail<DetailObject>
    typealias ReportListObject = Report.List
    typealias DetailObject = Tag.Detail.Detail
}
