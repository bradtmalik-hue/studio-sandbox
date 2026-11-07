import SwiftUI

struct AppPage2: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<3, id: \.self) { index in
                    Text("Page2 item \(index)")
                }
            }
            .navigationTitle("Page 2")
        }
    }
}
