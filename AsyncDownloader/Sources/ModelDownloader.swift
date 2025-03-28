//
//  ModelDownloader.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/11/25.
//

import Foundation

import AsyncAlgorithms


final actor ModelDownloader: Sendable {
    let id: String
    let localBaseURL: URL
    
    private let remoteBaseURL: URL
    
    init(id: String, localURL: URL, remoteURL: URL) {
        self.id = id
        self.remoteBaseURL = remoteURL
        self.localBaseURL = localURL
        
        var isDirectory: ObjCBool = true
        if FileManager.default.fileExists(atPath: localBaseURL.path(), isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                try? FileManager.default.removeItem(at: localBaseURL)
                try? FileManager.default.createDirectory(at: localBaseURL, withIntermediateDirectories: true)
            }
        } else {
            try? FileManager.default.createDirectory(at: localBaseURL, withIntermediateDirectories: true)
        }
    }
}

extension ModelDownloader {
    private nonisolated func getRequest(pathComponent: String, token: String?) -> URLRequest? {
        guard pathComponent.count > 0 else { return nil }
        
        var request = URLRequest(url: remoteBaseURL.appendingPathComponent(pathComponent))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private nonisolated func process(pathComponent: String, token: String?, channel: AsyncChannel<(String, Int, Int64)>) async -> Bool {
        // Check already downloaded
        let targetURL = localBaseURL.appendingPathComponent(pathComponent)
        guard !FileManager.default.fileExists(atPath: targetURL.path) else {
            ASLogger.logger.debug("Already downloaded: \(pathComponent)")
            await channel.send((id, 1, 1))  // increase total count
            await channel.send((id, 0, 1))  // increase progress count
            return true
        }
        guard let request = getRequest(pathComponent: pathComponent, token: token) else { return false }
                
        do {
// 1. download
//            // Change to file size
//            await channel.send((id, 1, 1))  // increase total count
//            // Download file
//            // To cover huge size of file, do not use data func, but download
//
//            let (location, response) = try await URLSession.shared.download(for: request)
//            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//                throw URLError(.badServerResponse)
//            }
//
//            // Check download cancellation and write file
//            try Task.checkCancellation()
//
//            // Move to local model directory
//            try FileManager.default.moveItem(at: location, to: targetURL)
//            ASLogger.logger.debug("Downloaded file: \(targetURL)")
//
//            // Change to file size
//            await channel.send((id, 0, 1))
//
//            return true
            
// 2. bytes
//            // Download a file with asynchronously count
//            let bufferSize = 20 * 1024 * 1024
//
//            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
//            await channel.send((id, 1, response.expectedContentLength))
//
//            let tempFileURL = FileManager.default.temporaryDirectory
//                .appendingPathComponent(UUID().uuidString + ".tmp")
//            FileManager.default.createFile(atPath: tempFileURL.path, contents: nil, attributes: nil)
//            let fileHandle = try FileHandle(forUpdating: tempFileURL)
//
//            var data = Data()
//            data.reserveCapacity(bufferSize)
//
//            // Download file
//            for try await byte in asyncBytes {
//                data.append(byte)
//                if data.count >= bufferSize {
//                    try fileHandle.write(contentsOf: data)
//                    await channel.send((id, 0, Int64(bufferSize)))
//                    data.removeAll(keepingCapacity: true)
//                }
//            }
//            if data.count > 0 {
//                try fileHandle.write(contentsOf: data)
//                await channel.send((id, 0, Int64(data.count)))
//            }
//            try fileHandle.close()
//
//            // Move to targetURL
//            try FileManager.default.moveItem(at: tempFileURL, to: targetURL)
//            ASLogger.logger.debug("Downloaded file: \(targetURL)")
//
//            return true
            
// 3. download with delegate
            // Change to file size
            //await channel.send((id, 1, 1))  // increase total count
            
            // Download file
            // To cover huge size of file, do not use data func, but download
            //let (location, response) = try await URLSession.shared.download(for: request, delegate: ProgressDelegate(id: id, channel: channel))
            let (location, response) = try await URLSession.shared.download(for: request, delegate: ProgressObserver(id: id, channel: channel))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            // Check download cancellation and write file
            try Task.checkCancellation()
            
            // Move to local model directory
            try FileManager.default.moveItem(at: location, to: targetURL)
            ASLogger.logger.debug("Downloaded file: \(targetURL)")
            
            // Change to file size
            //await channel.send((id, 0, 1))
            
            return true
        } catch {
            print("Failed to download \(pathComponent): \(error)")
            return false
        }
    }
}

extension ModelDownloader {
    func trigger(initialize: Bool, finalize: Bool, token: String?, channel triggerChannel: AsyncChannel<(Int, String)>) async -> (Task<Void, Never>, AsyncChannel<(String, Int, Int64)>) {
        let id = self.id
        let monitorChannel = AsyncChannel<(String, Int, Int64)>()

        if initialize {
            Task {
                await monitorChannel.send((id, 2, 0))
            }
        }
        
        let task = Task {
            await withTaskGroup(of: Bool.self) { taskGroup in
                //guard let downloadID = self?.id else { throw AsyncDownloaderError.downloadFailed }
                var cancelled = false
                var index = 0
                for await (message, targetPath) in triggerChannel {
                    switch message {
                    case 0: // download
                        if targetPath.count > 0 {
                            if index > Defaults.maximumDownloader {
                                if let validProgressing = await taskGroup.next(), validProgressing {
                                    // Do progressing
                                } else {
                                    // cancel download
                                    await monitorChannel.send((id, -1, 0))
                                    triggerChannel.finish()
                                    taskGroup.cancelAll()
                                    cancelled = true
                                }
                            }
                            taskGroup.addTask { [weak self] in
                                if Task.isCancelled { return false }
                                if let result = await self?.process(pathComponent: targetPath, token: token, channel: monitorChannel) {
                                    return result
                                } else {
                                    return false
                                }
                            }
                        } else {
                            // finish without finalizing
                            triggerChannel.finish()
                        }
                    default: // cancel
                        await monitorChannel.send((id, -1, 0))
                        taskGroup.cancelAll()
                        triggerChannel.finish()
                        cancelled = true
                    }
                    index += 1
                }
                // download completed
                if !cancelled {
                    for await result in taskGroup {
                        if !result {
                            // cancel download
                            await monitorChannel.send((id, -1, 0))
                            triggerChannel.finish()
                            taskGroup.cancelAll()
                            break
                        }
                    }
                    if finalize {
                        await monitorChannel.send((id, 3, 0))
                    }
                } else {
                    print("Download cancelled")
                }
                
                monitorChannel.finish()
            }
        }
        return (task, monitorChannel)
    }
    
    func download(paths: [String], channel: AsyncChannel<(Int, String)>) async {
        for path in paths {
            await channel.send((0, path))
        }
        await channel.send((0, ""))
    }
        
    func cancel(channel: AsyncChannel<(Int, String)>) async {
        await channel.send((-1, ""))
    }
        
}

final class ProgressDelegate: NSObject, URLSessionTaskDelegate {
    
    //nonisolated(unsafe) private var observer: NSKeyValueObservation?
    
    private let id: String
    private let channel: AsyncChannel<(String, Int, Int64)>
        
    init(id: String, channel: AsyncChannel<(String, Int, Int64)>) {
        self.id = id
        self.channel = channel
    }

    nonisolated func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        Task {
            await self.channel.send((self.id, 1, task.progress.totalUnitCount))
        }
        //observer = task.progress.observe(\.completedUnitCount, options: [.new]) {
        _ = task.progress.observe(\.completedUnitCount, options: [.new]) {
            _, count in
            //guard let url = task.originalRequest?.url else {
            //    return
            //}
            //guard let id = URLComponents(
            //    url: url,
            //    resolvingAgainstBaseURL: false
            //)?.queryItems?.first(where: { $0.name == "id" })?.value else {
            //    return
            //}
            Task {
                await self.channel.send((self.id, 0, count.newValue ?? 0))
            }
        }
    }
    
    //nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didReceiveInformationalResponse response: HTTPURLResponse) {
    //    guard response.expectedContentLength > 0 else { return }
    //    Task {
    //        print("merong merong")
    //        await channel.send((id, 1, response.expectedContentLength))
    //    }
    //}
    
}

final class ProgressObserver: NSObject, URLSessionTaskDelegate {
  
    nonisolated(unsafe) var observation: NSKeyValueObservation? = nil
    nonisolated(unsafe) var downloadedCount: Int64 = 0
  
    private let id: String
    private let channel: AsyncChannel<(String, Int, Int64)>
    
    init(id: String, channel: AsyncChannel<(String, Int, Int64)>) {
        self.id = id
        self.channel = channel
    }
  
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        observation = task.progress.observe(\.fractionCompleted, options: [.old, .new]) { progress, change in
            if let old = change.oldValue, let fraction = change.newValue {
                // Report file size
                if old == 0.0 {
                    Task {
                        await self.channel.send((self.id, 1, Int64(task.response?.expectedContentLength ?? 0)))
                    }
                }
                
                // Count downloaded
                var downloaded: Int64
                if fraction >= 1.0 {
                    downloaded = Int64(task.response?.expectedContentLength ?? 0) - self.downloadedCount
                } else {
                    downloaded = Int64((fraction - old) * Double(task.response?.expectedContentLength ?? 0))
                    self.downloadedCount += downloaded
                }
                
                Task {
                    await self.channel.send((self.id, 0, downloaded))
                }
            }
        }
    }
}
