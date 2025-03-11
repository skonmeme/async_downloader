//
//  ModelManagement.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/10/25.
//

import Foundation
import Observation
import SwiftUI

final class LanguageModel: Identifiable, Hashable {
    let id: UUID = UUID()
    var name: String = ""
    
    init(name: String) {
        self.name = name
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

final class ModelManagement: ObservableObject {
    @MainActor
    static let shared: ModelManagement = ModelManagement()
    
    @Published var models: [LanguageModel] = []
    @Published var progress: [UUID: (Int, Int)] = [:]
    
    init() {
        models.append(LanguageModel(name: "gemma-2-2b-it-vp_v1-q4f16_1-MLC"))
    }
}

extension ModelManagement {
    func getProgress(model: LanguageModel) -> (Int, Int) {
        if progress[model.id] == nil {
            progress[model.id] = (0, -1)
        }
        return progress[model.id]!
    }
    
    func startDownload(model: LanguageModel) {
        if progress[model.id] == nil {
            progress[model.id] = (0, -1)
        }
        progress[model.id]!.1 = 0
    }
    
    func updateDownload(model: LanguageModel, value: Int) {
        if progress[model.id] != nil {
            progress[model.id]!.0 = value
        }
    }
    
    func updateDownload(model: LanguageModel, value: Int, total: Int) {
        if progress[model.id] != nil {
            progress[model.id]!.0 = value
            progress[model.id]!.1 = total
        }
    }
}
