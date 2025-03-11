import SwiftUI

public struct ContentView: View {
    @EnvironmentObject private var modelManagement: ModelManagement
    
    public var body: some View {
        List {
            ForEach(modelManagement.models, id: \.self) { model in
                let progress = modelManagement.getProgress(model: model)
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(model.name)")
                        Text("Veresion")
                            .font(.caption)
                    }
                    Spacer()
                    if progress.1 >= 0 {
                        ProgressView(value: CGFloat(progress.0), total: CGFloat(progress.1))
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                            .frame(width: 60)
                    } else {
                        Button(action: {
                            startDownloadModel(model)
                        }, label: {
                            Text("Download")
                        })
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(15)
                        .font(.system(size:8))
                        .frame(width: 60)
                    }
                }
            }
        }
        Text("Hello, World!")
            .padding()
    }
    
    func startDownloadModel(_ model: LanguageModel) {
        modelManagement.startDownload(model: model)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelManagement.shared)
    }
}
