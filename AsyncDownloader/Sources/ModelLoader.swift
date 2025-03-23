//
//  ModelLoader.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/19/25.
//

import Foundation

import AsyncAlgorithms


final class ModelLoader: Sendable {
    static let shared = ModelLoader()
}

extension ModelLoader {
    func loadModels() async throws {
        //models.append(LanguageModel(name: "gemma-2-2b-it-vp_v1-q4f16_1-MLC", revision: "2025-01-01", modelType: .mlc, remoteURL: URL(string: Defaults.huggingFaceURL)!))
        
        var parameters: [ModelParameters] = []
        
        // Bundle models
        if FileManager.default.fileExists(atPath: Defaults.bundleConfigurationURL.path) {
            let fileHandle = try FileHandle(forReadingFrom: Defaults.bundleConfigurationURL)
            let bundConfigurations = try JSONDecoder().decode(ModelConfigurations.self, from: fileHandle.readDataToEndOfFile())
            parameters += bundConfigurations.modelParameters
        } else {
            ASLogger.logger.warning("Bundle configurations not found")
        }
        
        // Online models
        let (data, response) = try await URLSession.shared.data(from: Defaults.remoteConfigurationURL)
        if (response as? HTTPURLResponse)?.statusCode == 200 {
            let modelConfigurations = try JSONDecoder().decode(ModelConfigurations.self, from: data)
            parameters += modelConfigurations.modelParameters
        } else {
            print("Failed to fetch model configurations")
        }
        
        // register models
        for modelParameter in parameters {
            let model = LMConfiguration(parameters: modelParameter)
            await MainActor.run {
                ModelStates.shared.models.append(model)
                ModelStates.shared.initialize(model.id)
                if FileManager.default.fileExists(atPath: model.localBaseURL.appendingPathComponent(".done").path) {
                    ModelStates.shared.setState(model.id, state: .done)
                }
            }
        }
    }
    
}

extension ModelLoader {
    
    struct MLCComponents: Decodable {
        struct Component: Decodable {
            var dataPath: String
        }
        var records: [Component]
    }
    
    struct MLCConfigurations: Decodable {
        let tokenizerFiles: [String]
        var modelLib: String?
        var modelID: String?
        var estimatedVRAMReq: Int?

        enum CodingKeys: String, CodingKey {
            case tokenizerFiles = "tokenizer_files"
            case modelLib = "model_lib"
            case modelID = "model_id"
            case estimatedVRAMReq = "estimated_vram_req"
        }
    }
    
    private func download(paths: [String], downloader: ModelDownloader, token: String?, initialize: Bool = false, finalize: Bool = false) async -> AsyncChannel<(Int, String)>? {
        let triggerChannel = AsyncChannel<(Int, String)>()

        let task0: Task = Task {
            let (downloadTask, monitorChannel) = await downloader.trigger(initialize: initialize, finalize: finalize, token: token, channel: triggerChannel)
            for await message in monitorChannel {
                ASLogger.logger.debug("\(message.0): \(message.1): \(message.2)")
                await MainActor.run {
                    ModelStates.shared.send(message)
                }
            }

            if !finalize {
                // wait to perform next download
                _ = await downloadTask.value
            }
        }
        
        let task1 = Task {
            await downloader.download(paths: paths, channel: triggerChannel)
        }
        
        if !finalize {
            // wait to perform next download
            _ = await [task0.value, task1.value]
            return nil
        } else {
            return triggerChannel
        }
    }

    private func mlcDownload(downloader: ModelDownloader, token: String?) async -> AsyncChannel<(Int, String)>? {
        do {
            // Download configuration files
            _ = await download(paths: Defaults.mlcConfigurationFiles, downloader: downloader, token: token, initialize: true)
            
            // Load configuration with Tokenizer files
            let configurationURL = downloader.localBaseURL.appendingPathComponent(Defaults.mlcConfigurationFile)
            let configurationFileHandle = try FileHandle(forReadingFrom: configurationURL)
            let configurationData = configurationFileHandle.readDataToEndOfFile()
            let configurations = try JSONDecoder().decode(MLCConfigurations.self, from: configurationData)
            
            // Load model component files
            let componentURL = downloader.localBaseURL.appendingPathComponent(Defaults.mlcComponentFile)
            let componentFileHandle = try FileHandle(forReadingFrom: componentURL)
            let componentData = componentFileHandle.readDataToEndOfFile()
            let components = try JSONDecoder().decode(MLCComponents.self, from: componentData)
            
            // Download files
            let files = configurations.tokenizerFiles + components.records.map { $0.dataPath }
            return await download(paths: files, downloader: downloader, token: token, finalize: true)
        } catch {
            ASLogger.logger.warning("Failed to load MLC configuration files: \(error)")
            return nil
        }
    }

    private func mlxDownload(components: [String], downloader: ModelDownloader, token: String?) async -> AsyncChannel<(Int, String)>? {
            // Download configuration files
        return await download(paths: components, downloader: downloader, token: token, initialize: true, finalize: true)
    }
    
    func startDownload(model: LMConfiguration, token: String?) async -> (ModelDownloader?, AsyncChannel<(Int, String)>?) {
        guard let remoteURL = model.remoteBaseURL else { return (nil, nil) }
        let downloader = ModelDownloader(id: model.id, localURL: model.localBaseURL, remoteURL: remoteURL)
        var channel: AsyncChannel<(Int, String)>? = nil
        
        switch model.platform {
        case .mlc:
            channel = await mlcDownload(downloader: downloader, token: token)
        case .mlx:
            if let modelParameters = model.modelParameters, let components = modelParameters.components {
                channel = await mlxDownload(components: components,  downloader: downloader, token: token)
            }
        }
        
        return (downloader, channel)
    }
    
    func cancelDownload(downloader: ModelDownloader, channel: AsyncChannel<(Int, String)>) async {
        await downloader.cancel(channel: channel)
    }
    
}
