//
//  ModelDownloader.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/11/25.
//

import AsyncAlgorithms
import Foundation

final actor ModelDownloader {
    private let remoteBaseURL: URL
    private let localBaseURL: URL

    private var channels: [String: AsyncChannel<[String]>] = [:]
    
    init(remoteURL: URL, localURL: URL) {
        self.remoteBaseURL = remoteURL
        self.localBaseURL = localURL
    }
}

extension ModelDownloader {
    private func getChannel(_ id: String) -> AsyncChannel<[String]> {
        if channels[id] == nil {
            channels[id] = AsyncChannel<[String]>()
        }
        return channels[id]!
    }
}

extension ModelDownloader {
    private func getRequest(pathComponents: [String], token: String?) -> URLRequest {
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
    
    private nonisolated func downloader(pathComponents: [String], token: String?) async throws {
        
    }
}

extension ModelDownloader {
    func trigger(_ id: String, token: String?) async throws {
        let channel = getChannel(id)
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            var index = 0
            for await targetPath in channel {
                if targetPath.count > 0 {
                    if index > Defaults.maximumDownloader {
                        try await taskGroup.next()
                    }
                    taskGroup.addTask {
                        try await self.downloader(pathComponents: targetPath, token: token)
                    }
                } else {
                    channel.finish()
                }
                index += 1
            }
            
            for try await _ in taskGroup {
                
            }
        }
    }
    
    
}
