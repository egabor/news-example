//
//  BaseApi.swift
//  news-example
//
//  Created by Eszenyi Gábor on 2021. 04. 14..
//

import Foundation
import Alamofire
import Combine

enum BaseApiError: Error {
    case generalError
}

public typealias EmptyResponse = Alamofire.Empty

public class BaseApi {

    var baseUrl: String
    var apiKey: String

    var headers: [String: String]

    @Injected var decoder: JSONDecoder
    @Injected var encoder: JSONEncoder

    init(baseUrl: String, apiKey: String) {
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Api-Key": apiKey
        ]
    }

    func buildRequest<T: Codable>(with requestData: URLRequestConvertible) -> Future<T, Error> {
        return Future { promise in
            AF.request(requestData)
                .validate(statusCode: 200...299)
                .responseDecodable(
                    decoder: self.decoder,
                    completionHandler: { (response: DataResponse<T, AFError>) in
                        switch response.result {
                        case let .success(result):
                            promise(.success(result))
                        case .failure:
                            guard let data = response.data,
                                  let errorObject = self.convertToNetworkError(data: data) else {
                                promise(.failure(BaseApiError.generalError))
                                return
                            }
                            promise(.failure(errorObject))
                        }
                    })
        }
    }

    internal func convertToData<T: Encodable>(data: T) -> Data? {
        do {
            return try encoder.encode(data)
        } catch {
            return nil
        }
    }

    internal func convertToNetworkError(data: Data) -> NetworkError? {
        do {
            return try decoder.decode(NetworkError.self, from: data)
        } catch {
            return nil
        }
    }
}
