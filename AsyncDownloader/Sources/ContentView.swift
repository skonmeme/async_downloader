import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var modelManagement: ModelManagement

    public var body: some View {
        ListView() {
            ForEach(modelManagement.models) { model in
                HStack {
                    Text(model.name)
                    Spacer()
                    
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
    }
}
