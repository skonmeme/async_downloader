//
//  ModelManagement.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/10/25.
//

import SwiftUI

struct Model: Identifiable {
    var id: Int
    var name: String
    var progress: (Int, Int)
}

final class ModelManagement: ObservableObject {
    @Published var models: [Int: Model] = [:]
    
    init() {
        models[0] = Model(id: 0, name: "gemma-2-2b-it-vp_v1-q4f16_1-MLC", progress: (0, 0))
    }
}
