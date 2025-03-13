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

final class ModelState: ObservableObject {
    @MainActor
    static let shared = ModelState()
    
    @Published var models: [LanguageModel] = []
    @Published var state: [String: DownloadState] = [:]
    @Published var progress: [String: (Int, Int)] = [:]

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
    }
    
    func getState(_ id: String) -> (DownloadState, Int, Int) {
        if state[id] == nil {
            initialize(id)
        }
        return (state[id]!, progress[id]!.0, progress[id]!.1)
    }
}

final class ModelManagement {
    @MainActor
    static let shared = ModelManagement()
}

extension ModelManagement {
    func startDownload(_ id: String, token: String?) {
        let downloader = ModelDownloader(id: id, remoteURL: URL(string: "https://huggingface.co/skonmeme")!)
        let triggerChannel = AsyncChannel<[String]>()
        
        Task {
            let monitorChannel = await downloader.trigger(token: token, channel: triggerChannel)
            for await message in monitorChannel {
                await MainActor.run { ModelState.shared.add(message) }
            }
        }
        
        Task {
            await downloader.download(paths: Defaults.mlcConfigurationFiles, channel: triggerChannel)
        }
    }
}
