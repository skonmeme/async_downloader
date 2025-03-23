//
//  LanguageModel.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/18/25.
//

import CryptoKit
import Foundation

enum Platform: String, Decodable {
    case mlc
    case mlx
}

enum ModelType: String, Decodable {
    case gemma2
    case gemma3
    case qwen2_5 = "qwen-2.5"
}

struct ModelParameters: Decodable {
    var name: String
    var revision: String
    var platform: Platform
    var modelType: ModelType
    var remotePath: String? = nil
    var estimatedVramBytes: Int? = nil
    var overrides: [String: Int]? = nil
    var components: [String]? = nil

    enum CodingKeys: String, CodingKey {
        case name
        case revision
        case remotePath = "remote_url"
        case platform
        case modelType = "model_type"
        case components
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

final class LMConfiguration: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let revision: String
    let platform: Platform
    let localBaseURL: URL
    let bundled: Bool
    let remoteBaseURL: URL?
    let modelParameters: ModelParameters?
    
    init(parameters: ModelParameters) {
        let hashCode = SHA256.hash(data: Data((parameters.name + parameters.revision).utf8))

        //self.modelType = parameters.modelType
        self.platform = parameters.platform
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

extension LMConfiguration {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: LMConfiguration, rhs: LMConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
}
