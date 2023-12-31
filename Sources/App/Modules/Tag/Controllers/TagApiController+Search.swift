import AppApi
import Fluent
import Vapor

extension TagApiController: ApiElasticSearchController {
    // MARK: - Validators

    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }

    // MARK: - Search

    func searchQuery(_ searchContext: AppApi.DefaultSearchContext, _ pageRequest: Fluent.PageRequest, on elastic: ElasticHandler) async throws -> [String: Any] {
        [
            "from": (pageRequest.page - 1) * pageRequest.per,
            "size": pageRequest.per,
            "query": [
                "multi_match": [
                    "query": searchContext.text,
                    "fields": ["title", "keywords"],
                ],
            ],
        ]
    }

    func searchOutput(_ req: Vapor.Request, _ model: LatestVerifiedTagModel.Elasticsearch) async throws -> Tag.Detail.List {
        .init(id: model.id, title: model.title, slug: model.slug)
    }
}
