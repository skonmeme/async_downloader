//
//  ModelDownloader.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/11/25.
//

import AsyncAlgorithms
import Foundation

final actor ModelDownloader: Sendable {
    private let id: String
    private let remoteBaseURL: URL
    private let localBaseURL: URL
    
    init(id: String, remoteURL: URL) {
        self.id = id
        self.remoteBaseURL = remoteURL.appendingPathComponent("resolve").appendingPathComponent("main")
        self.localBaseURL = Defaults.documentsURL.appendingPathComponent(id)
    }
}

extension ModelDownloader {
    private nonisolated func getRequest(pathComponents: [String], token: String?) -> URLRequest? {
        guard pathComponents.count > 0 else { return nil }
        
        var url = remoteBaseURL
        for path in pathComponents {
            url = url.appendingPathComponent(path)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private nonisolated func process(pathComponents: [String], token: String?, channel: AsyncChannel<(String, Int, Int)>) async {
        guard let request = getRequest(pathComponents: pathComponents, token: token) else { return }
        
        var localURL = localBaseURL
        for path in pathComponents {
            localURL = localURL.appendingPathComponent(path)
        }
        
        do {
            // Download file
            // To cover huge size of file, do not use data func, but download
            let (location, response) = try await URLSession.shared.download(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // Check download cancellation and write file
            try Task.checkCancellation()
            
            try FileManager.default.moveItem(at: location, to: localURL)
            // send a message of successful download
            await channel.send((id, 0, 1))
        } catch {
            // need to implement
        }
    }
}

extension ModelDownloader {
    func trigger(token: String?, channel triggerChannel: AsyncChannel<[String]>) async -> AsyncChannel<(String, Int, Int)> {
        let monitorChannel = AsyncChannel<(String, Int, Int)>()
        Task {
            await withTaskGroup(of: Void.self) { [weak self] taskGroup in
                //guard let downloadID = self?.id else { throw AsyncDownloaderError.downloadFailed }
                var index = 0
                for await targetPath in triggerChannel {
                    if targetPath.count > 0 {
                        if index > Defaults.maximumDownloader {
                            await taskGroup.next()
                        }
                        taskGroup.addTask { [weak self] in
                            await self?.process(pathComponents: targetPath, token: token, channel: monitorChannel)
                        }
                    } else {
                        triggerChannel.finish()
                    }
                    index += 1
                }
            }
        }
        return monitorChannel
    }
    
    func download(paths: [[String]], channel: AsyncChannel<[String]>) async {
        for path in paths {
            await channel.send(path)
        }
        await channel.send([])
    }
}
