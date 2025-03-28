//
//  ModelState.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/10/25.
//

import CryptoKit
import Foundation
import Observation
import SwiftUI

import AsyncAlgorithms

//
// Messsage type
//   0: progressing
//   1: total changing
//   2: start downloading
//   3: finish
//  -1: cancel
//

enum DownloadState {
    case ready
    case downloading
    case done
    case invalid
}

struct ModelState {
    var state: DownloadState
    var progress: Int64
    var total: Int64
}

@Observable final class ModelStates {
    @MainActor
    static let shared = ModelStates()
    
    var models: [LMConfiguration] = []
    var state: [String: DownloadState] = [:]
    var progress: [String: Int64] = [:]
    var total: [String: Int64] = [:]
}

extension ModelStates {
    func initialize(_ id: String) {
        state[id] = .ready
        progress[id] = 0
        total[id] = 0
    }
    
    func setState(_ id: String, state newState: DownloadState) {
        state[id] = newState
    }
    
    // message: (ID, type, value)
    func send(_ message: (String, Int, Int64)) {
        let (id, type, value) = message
        switch type {
        case 0: // progressing
            progress[id, default: 0] += value
        case 1: // total changing
            state[id] = .downloading
            total[id, default: 0] += value
        case 2: // start downloading
            state[id] = .downloading
            progress[id] = 0
            total[id] = 0
        case 3: // finish
            if progress[id] != nil && progress[id] == total[id] {
                ASLogger.logger.info("Downloaded: \(id)")
                state[id] = .done
                
                // Create a .done file
                let model = models.first { $0.id == id }
                let doneURL = model!.localBaseURL.appendingPathComponent(".done")
                do {
                    try Data().write(to: doneURL)
                } catch {
                    ASLogger.logger.warning("Failed to create a .done file: \(error)")
                }
            } else {
                ASLogger.logger.warning("Invalid download: \(id): \(self.progress[id, default: 0]) / \(self.progress[id, default: 0])")
                state[id] = .invalid
            }
        default: // cancel
            initialize(id)
            state[id] = .invalid
        }
    }
    
    func get(_ id: String) -> ModelState {
        return ModelState(state: state[id, default: .ready],
                          progress: progress[id, default: 0],
                          total: total[id, default: 0])
    }
}
