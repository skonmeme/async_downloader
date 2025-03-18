import SwiftUI

import AsyncAlgorithms


fileprivate struct ReadyView: View {
    @Environment(ModelStates.self) private var modelStates
    @State var model: LanguageModel
    @Binding var huggingfaceToken: String
    @Binding var downloader: ModelDownloader?
    @Binding var channel: AsyncChannel<(Int, String)>?
        
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(model.name)")
                HStack {
                    Text("\(model.modelType.rawValue.uppercased())")
                        .padding(5)
                        .font(.caption)
                        .background(Color.blue)
                        .cornerRadius(10)
                    Text("\(model.revision)")
                        .padding(2)
                        .font(.caption)
                        .foregroundColor(.gray)
                    if modelStates.get(model.id).state == .invalid {
                        Text("Download cancelled")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Button(action: {
                startDownloadModel()
            }, label: {
                Text("Download")
            })
            .buttonStyle(.borderedProminent)
            .cornerRadius(15)
            .font(.system(size:8))
            .frame(width: 60)
        }
    }
    
    func startDownloadModel() {
        let token = huggingfaceToken.isEmpty ? nil : huggingfaceToken
        Task {
            let (d, c) = await ModelLoader.shared.startDownload(model: model, token: token)
            await MainActor.run {
                (downloader, channel) = (d, c)
            }
        }
    }
}

fileprivate struct DownloadingView: View {
    @Environment(ModelStates.self) private var modelStates
    @State var model: LanguageModel
    @Binding var downloader: ModelDownloader?
    @Binding var channel: AsyncChannel<(Int, String)>?
    
    public var body: some View {
        let state = modelStates.get(model.id)
        HStack {
            VStack(alignment: .leading) {
                Text("\(model.name)")
                HStack {
                    Text("\(model.modelType.rawValue.uppercased())")
                        .padding(5)
                        .font(.caption)
                        .background(Color.blue)
                        .cornerRadius(10)
                    Text("\(model.revision)")
                        .padding(2)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            //Text("Progress: \(state.progress) / \(state.total)")
            Button(action: {
                cancelDownload()
            }, label: {
                // Recommend customizing ProgressViewStyle
                ProgressView(value: CGFloat(state.progress), total: CGFloat(state.total))
                .progressViewStyle(.circular)
                .scaleEffect(0.5)
            })
            .buttonStyle(.borderless)
        }
    }
    
    func cancelDownload() {
        guard let downloader = downloader, let channel = channel else { return }
        Task {
            await ModelLoader.shared.cancelDownload(downloader: downloader, channel: channel)
        }
    }
}

fileprivate struct DoneView: View {
    @Environment(ModelStates.self) private var modelStates
    @State var model: LanguageModel
    @State var deleteModelRequested: Bool = false
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(model.name)")
                HStack {
                    Text("\(model.modelType.rawValue.uppercased())")
                        .padding(5)
                        .font(.caption)
                        .background(Color.blue)
                        .cornerRadius(10)
                    Text("\(model.revision)")
                        .padding(2)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: {
                deleteModelRequested = true
            }, label: {
                Image(systemName: "checkmark.seal.fill")
                        .frame(width: 60)
                        .foregroundColor(.blue)
            })
            .buttonStyle(.borderless)
            .border(.red, width: 1)
        }
        .confirmationDialog("Delete the model", isPresented: $deleteModelRequested) {
            Button("Delete", role: .destructive, action: { removeModel() })
            Button("Cancel", role: .cancel, action: {})
        }
    }
    
    func removeModel() {
        do {
            try FileManager.default.removeItem(at: model.localBaseURL)
            modelStates.initialize(model.id)
        } catch {
            print("Failed to remove model: \(error)")
        }
    }
}

public struct ContentView: View {
    @Environment(ModelStates.self) private var modelStates: ModelStates
    @State private var huggingfaceToken: String = ""
    @State private var modelDownloader: ModelDownloader? = nil
    @State private var triggerChannel: AsyncChannel<(Int, String)>? = nil
    
    public var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Huggingface token")
                TextField("token", text: $huggingfaceToken)
            }
            .padding()
            List {
                ForEach(modelStates.models) { model in
                    let state = modelStates.get(model.id)
                    switch state.state {
                    case .downloading:
                        DownloadingView(model: model, downloader: $modelDownloader, channel: $triggerChannel)
                            .environment(modelStates)
                    case .done:
                        DoneView(model: model)
                            .environment(modelStates)
                    case .invalid:
                        ReadyView(model: model, huggingfaceToken: $huggingfaceToken, downloader: $modelDownloader, channel: $triggerChannel)
                            .environment(modelStates)
                    default:
                        ReadyView(model: model, huggingfaceToken: $huggingfaceToken, downloader: $modelDownloader, channel: $triggerChannel)
                            .environment(modelStates)
                    }
                }
            }
        }
        Text("Hello, World!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(ModelStates())
    }
}
