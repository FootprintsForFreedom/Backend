import ElasticsearchNIOClient
import Fluent
import Vapor

extension Application {
    /// The elasticsearch client to interact with elasticsearch.
    private var elasticClient: ElasticsearchClient {
        get throws {
            try ElasticsearchClient(
                httpClient: http.client.shared,
                eventLoop: eventLoopGroup.next(),
                logger: logger,
                url: Environment.elasticsearchUrl,
                jsonEncoder: ElasticHandler.newJSONEncoder(),
                jsonDecoder: ElasticHandler.newJSONDecoder()
            )
        }
    }

    /// The elasticsearch handler.
    var elastic: ElasticHandler {
        get throws {
            try .init(elastic: elasticClient)
        }
    }
}

extension Request {
    /// The elasticsearch client to interact with elasticsearch.
    private var elasticClient: ElasticsearchClient {
        get throws {
            try ElasticsearchClient(
                httpClient: application.http.client.shared,
                eventLoop: eventLoop,
                logger: logger,
                url: Environment.elasticsearchUrl,
                jsonEncoder: ElasticHandler.newJSONEncoder(),
                jsonDecoder: ElasticHandler.newJSONDecoder()
            )
        }
    }

    /// The elasticsearch handler
    var elastic: ElasticHandler {
        get throws {
            try .init(elastic: elasticClient)
        }
    }
}
