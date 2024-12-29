//
//  RequestError.swift
//  NetworkTest
//
//  Created by Nikolay Budai on 02/12/24.
//

import Foundation

public enum RequestError: Error {
    case decoding
    case encoding
    case invalidURL
    case noResponse
    case unauthorized
    case unexpectedStatusCode
    case unknown
    
    var customMessage: String {
        switch self {
        case .decoding: return "Decoding error"
        case .encoding: return "Encoding error"
        case .invalidURL: return "Invalid url"
        case .noResponse: return "No response recieved"
        case .unauthorized: return "Session expired"
        default:
            return "Unknown error"
        }
    }
}
