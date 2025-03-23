//
//  Defaults.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/10/25.
//

import Foundation

struct Defaults {
    static let baseModelURL: URL = {
        //try! FileManager.default.url(for: .documentDirectory,
        //                             in: .userDomainMask,
        //                             appropriateFor: nil,
        //                             create: false)
        try! FileManager.default.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
        .appendingPathComponent("AsyncDownloader")
        .appendingPathComponent("models")
    }()
    static let bundleModelURL = Bundle.main.bundleURL.appendingPathComponent("bundle")
    
    static let remoteConfigurationURL = URL(string: "https://huggingface.co/datasets/skonmeme/mlc_llm_configurations/resolve/main/iphone_models.json")!
    static let bundleConfigurationURL = bundleModelURL.appendingPathComponent("iphone_models.json")

    static let mlcConfigurationFile = "mlc-chat-config.json"
    static let mlcComponentFile = "ndarray-cache.json"
    static let mlcConfigurationFiles = [mlcConfigurationFile, mlcComponentFile]
    
    static let mlxConfigurationFile = "mlx-config.json"
    static let mlxConfigurationFiles = [mlxConfigurationFile]

    static let maximumDownloader = 3
}
