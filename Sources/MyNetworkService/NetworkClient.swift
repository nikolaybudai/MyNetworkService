//
//  NetworkClient.swift
//  NetworkTest
//
//  Created by Nikolay Budai on 02/12/24.
//

import Foundation

public protocol NetworkClient {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError>
    func sendPostRequest<T: Decodable, U: Encodable>(endpoint: Endpoint, requestBody: U, responseModel: T.Type? = nil) async -> Result<T?, RequestError>
}

@available(iOS 15.0, *)
public extension NetworkClient {
    func sendRequest<T: Decodable>(
        endpoint: Endpoint,
        responseModel: T.Type
    ) async -> Result<T, RequestError> {
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host
        urlComponents.port = endpoint.port
        urlComponents.path = endpoint.path
        urlComponents.queryItems = endpoint.queryItems
        
        guard let url = urlComponents.url else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header

        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }
            switch response.statusCode {
            case 200...299:
                guard let decodedResponse = try? JSONDecoder().decode(responseModel, from: data) else {
                    return .failure(.decoding)
                }
                return .success(decodedResponse)
            case 401:
                return .failure(.unauthorized)
            default:
                return .failure(.unexpectedStatusCode)
            }
        } catch {
            return .failure(.unknown)
        }
    }
    
    extension NetworkClient {
        func sendPostRequest<T: Decodable, U: Encodable>(
            endpoint: Endpoint,
            requestBody: U,
            responseModel: T.Type? = nil
        ) async -> Result<T?, RequestError> {
            var urlComponents = URLComponents()
            urlComponents.scheme = endpoint.scheme
            urlComponents.host = endpoint.host
            urlComponents.path = endpoint.path
            urlComponents.queryItems = endpoint.queryItems

            guard let url = urlComponents.url else {
                return .failure(.invalidURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = endpoint.header
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                request.httpBody = try JSONEncoder().encode(requestBody)
            } catch {
                return .failure(.encoding)
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
                guard let httpResponse = response as? HTTPURLResponse else {
                    return .failure(.noResponse)
                }

                switch httpResponse.statusCode {
                case 200...299:
                    if let responseModel = responseModel {
                        do {
                            let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
                            return .success(decodedResponse)
                        } catch {
                            return .failure(.decoding)
                        }
                    } else {
                        return .success(nil)
                    }
                case 401:
                    return .failure(.unauthorized)
                default:
                    return .failure(.unexpectedStatusCode)
                }
            } catch {
                return .failure(.unknown)
            }
        }
    }
}
