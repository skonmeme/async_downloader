//
//  ModelManagement.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/10/25.
//

import AsyncAlgorithms
import CryptoKit
import Foundation
import Observation
import SwiftUI

final class LanguageModel: Identifiable, Hashable {
    let id: String
    var name: String
    var revision: String
    
    init(name: String, revision: String) {
        let hashCode = SHA256.hash(data: Data((name + revision).utf8))

        self.id = hashCode.compactMap { String(format: "%02hhx", $0) }.joined()
        self.name = name
        self.revision = revision
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

enum DownloadState {
    case ready
    case downloading
    case done
}

@Observable final class ModelState {
    @MainActor
    static let shared = ModelState()
    
    var models: [LanguageModel] = []
    var state: [String: DownloadState] = [:]
    var progress: [String: (Int, Int)] = [:]

    init() {
        models.append(LanguageModel(name: "gemma-2-2b-it-vp_v1-q4f16_1-MLC", revision: "2025-01-01"))
    }
    
    private func initialize(_ id: String) {
        state[id] = .ready
        progress[id] = (0, -1)
    }
    
    // message: (ID, type, value)
    func add(_ message: (String, Int, Int)) {
        let (id, type, value) = message
        switch type {
        case 0: // progressing
            progress[id]!.0 += value
        case 1: // total changing
            state[id] = .downloading
            progress[id]!.1 += value
        case 2: // finish
            progress[id]!.0 = progress[id]!.1
            state[id] = .done
        default: // cancel
            initialize(id)
        }
        print("ID: \(id), Progress: \(progress)")
    }
    
    func getState(_ id: String) -> (DownloadState, Int, Int) {
        if state[id] == nil {
            initialize(id)
        }
        return (state[id]!, progress[id]!.0, progress[id]!.1)
    }
}

final class ModelManagement {
}

extension ModelManagement {
    func startDownload(id: String, name: String, token: String?) {
        guard let remoteURL = URL(string: "https://huggingface.co/skonmeme")?.appendingPathComponent(name) else { return }
        let downloader = ModelDownloader(id: id, remoteURL: remoteURL)
        let triggerChannel = AsyncChannel<[String]>()

        Task {
            let monitorChannel = await downloader.trigger(token: token, channel: triggerChannel)
            for await message in monitorChannel {
                print("\(message)")
                await MainActor.run {
                    print("m100")
                    //ModelState.shared.progress["gemma-2-2b-it-vp_v1-q4f16_1-MLC"]!.1 = 0
                    ModelState.shared.progress[id] = (10, 20)
                    //ModelState.shared.add(message)
                }
            }
        }
        
        Task {
            print("Start download config files")
            await downloader.download(paths: Defaults.mlcConfigurationFiles, channel: triggerChannel)
        }
    }
}
