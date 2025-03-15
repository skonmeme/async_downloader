//
//  Defaults.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/10/25.
//

import Foundation

struct Defaults {
    static let huggingFaceURL = "https://huggingface.co/skonmeme"
    static let documentsURL: URL = {
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
    }()
    static let mlcConfigurationFiles = [["mlc-chat-config.json"], ["ndarray-cache.json"]]

    static let maximumDownloader = 3
}
