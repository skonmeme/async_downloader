//
//  MLXLLMEvaluator.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/24/25.
//

import Foundation
import SwiftUI

import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import MarkdownUI
import Metal
import Tokenizers

@Observable
@MainActor
class MLXLLMEvaluator {

    var running = false

    var includeWeatherTool = false

    var output = ""
    var modelInfo = ""
    var stat = ""

    /// This controls which model loads. `qwen2_5_1_5b` is one of the smaller ones, so this will fit on
    /// more devices.
    //let modelConfiguration = ModelRegistry.qwen2_5_1_5b

    /// parameters controlling the output
    let generateParameters = GenerateParameters(temperature: 0.6)
    //let maxTokens = 240
    let maxTokens = 4096

    /// update the display every N tokens -- 4 looks like it updates continuously
    /// and is low overhead.  observed ~15% reduction in tokens/s when updating
    /// on every token
    let displayEveryNTokens = 4

    enum LoadState {
        case idle
        case loaded((String, ModelContainer))
    }

    var loadState = LoadState.idle

    let currentWeatherToolSpec: [String: any Sendable] =
        [
            "type": "function",
            "function": [
                "name": "get_current_weather",
                "description": "Get the current weather in a given location",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": [
                            "type": "string",
                            "description": "The city and state, e.g. San Francisco, CA",
                        ] as [String: String],
                        "unit": [
                            "type": "string",
                            "enum": ["celsius", "fahrenheit"],
                        ] as [String: any Sendable],
                    ] as [String: [String: any Sendable]],
                    "required": ["location"],
                ] as [String: any Sendable],
            ] as [String: any Sendable],
        ] as [String: any Sendable]

    /// initialize and return the model -- can be called multiple times, subsequent calls will
    /// just return the loaded model
    func initialize(_ lmConfiguration: LMConfiguration) async throws -> ModelContainer {
        switch loadState {
        case .idle:
            // limit the buffe cache
            // 20MB default... Is it ok???
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            let modelConfiguration = ModelConfiguration(directory: lmConfiguration.localBaseURL)
            let modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: modelConfiguration) { [modelConfiguration] progress in
                Task { @MainActor in
                    self.modelInfo = "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                }
            }
            let numParams = await modelContainer.perform { context in
                context.model.numParameters()
            }
            
            self.modelInfo =
            "Loaded \(modelConfiguration.id).  Weights: \(numParams / (1024*1024))M"
            loadState = .loaded((lmConfiguration.id, modelContainer))
            return modelContainer
        case .loaded(let (id, modelContainer)):
            if id == lmConfiguration.id {
                return modelContainer
            } else {
                shutdown()
                return try await initialize(lmConfiguration)
            }
        }
    }
    
    // release the memory allocated by the model
    func shutdown() {
        switch loadState {
        case .loaded:
            loadState = .idle
        case .idle: break
        }
    }
    
    func generate(userPrompt: String, systemPrompt: String, lmConfiguration: LMConfiguration) async {
        guard !running else { return }

        running = true
        self.output = ""

        do {
            let modelContainer = try await initialize(lmConfiguration)

            // each time you generate you will get something new
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            let result = try await modelContainer.perform { context in
                //let input = try await context.processor.prepare(
                //    input: .init(
                //        messages: [
                //            ["role": "system", "content": "You are a helpful assistant."],
                //            ["role": "user", "content": prompt],
                //        ], tools: includeWeatherTool ? [currentWeatherToolSpec] : nil))
                let input = try await context.processor.prepare(
                    input: .init(
                        messages: [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userPrompt],
                        ]))
                return try MLXLMCommon.generate(
                    input: input, parameters: generateParameters, context: context
                ) { tokens in
                    // Show the text in the view as it generates
                    if tokens.count % displayEveryNTokens == 0 {
                        let text = context.tokenizer.decode(tokens: tokens)
                        Task { @MainActor in
                            self.output = text
                        }
                    }
                    if tokens.count >= maxTokens {
                        return .stop
                    } else {
                        return .more
                    }
                }
            }

            // update the text if needed, e.g. we haven't displayed because of displayEveryNTokens
            if result.output != self.output {
                self.output = result.output
            }
            self.stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"

        } catch {
            output = "Failed: \(error)"
        }

        running = false
    }
}
