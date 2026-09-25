import SwiftUI

struct ContentView: View {
    @State private var desk = PassDesk()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        PassRoot()
            .environment(desk)
            .task { await desk.boot() }
            .onChange(of: scenePhase) { _, phase in
                Task { await desk.handle(phase: phase) }
            }
    }
}

#Preview {
    ContentView()
}
