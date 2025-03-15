import SwiftUI

public struct ContentView: View {
    @Environment(ModelState.self) private var modelState: ModelState
    @State private var huggingfaceToken: String = ""
    
    public var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Huggingface token")
                TextField("token", text: $huggingfaceToken)
            }
            .padding()
            List {
                ForEach(modelState.models, id: \.self) { model in
                    let state = modelState.getState(model.id)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(model.name)")
                            Text("Veresion")
                                .font(.caption)
                        }
                        Spacer()
                        if state.2 >= 0 {
                            ProgressView(value: CGFloat(state.1), total: CGFloat(state.2))
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
        }
        Text("Hello, World!")
            .padding()
    }
    
    func startDownloadModel(_ model: LanguageModel) {
        let token = huggingfaceToken.isEmpty ? nil : huggingfaceToken
        ModelManagement().startDownload(id: model.id, name: model.name, token: token)
        //modelState.progress[model.id] = (3, 10)
        print(model.id)
        ModelState.shared.progress["gemma-2-2b-it-vp_v1-q4f16_1-MLC"] = (10, 40)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(ModelState())
    }
}
