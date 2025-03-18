//
//  LanguageModel.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/18/25.
//

import CryptoKit
import Foundation

enum ModelType: String, Decodable {
    case mlc
    case mlx
}

struct ModelParameters: Decodable {
    var name: String
    var revision: String
    var modelType: ModelType
    var remotePath: String?
    var estimatedVramBytes: Int
    var overrides: [String: Int]

    enum CodingKeys: String, CodingKey {
        case name
        case revision
        case remotePath = "remote_url"
        case modelType = "model_type"
        case estimatedVramBytes = "estimated_vram_bytes"
        case overrides
    }
}

struct ModelConfigurations: Decodable {
    var device: String
    var revision: String
    var modelParameters: [ModelParameters]

    enum CodingKeys: String, CodingKey {
        case device
        case revision
        case modelParameters = "model_list"
    }
}

final class LanguageModel: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let revision: String
    let modelType: ModelType
    let localBaseURL: URL
    let bundled: Bool
    let remoteBaseURL: URL?
    let modelParameters: ModelParameters?
    
    init(parameters: ModelParameters) {
        let hashCode = SHA256.hash(data: Data((parameters.name + parameters.revision).utf8))

        self.modelType = parameters.modelType
        self.name = parameters.name
        self.revision = parameters.revision
        self.id = hashCode.compactMap { String(format: "%02hhx", $0) }.joined()
        self.modelParameters = parameters

        // Check if the model is bundled
        if let remotePath = parameters.remotePath {
            let remoteURL = URL(string: remotePath)!
            self.localBaseURL = Defaults.baseModelURL.appendingPathComponent(id)
            self.remoteBaseURL = remoteURL.appendingPathComponent("resolve").appendingPathComponent("main")
            self.bundled = false
        } else {
            var isDirectory: ObjCBool = true
            if FileManager.default.fileExists(atPath: Defaults.bundleModelURL.appendingPathComponent(id).path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    self.localBaseURL = Defaults.bundleModelURL.appendingPathComponent(id)
                    self.remoteBaseURL = nil
                    self.bundled = true
                } else {
                    fatalError("Invalid bundle model: \(self.name)")
                }
            } else {
                fatalError("Invalid bundle model: \(self.name)")
            }
        }
    }
}

extension LanguageModel {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: LanguageModel, rhs: LanguageModel) -> Bool {
        return lhs.id == rhs.id
    }
}
