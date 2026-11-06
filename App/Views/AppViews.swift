import SwiftUI

struct AppViews: View {
    var body: some View {
        List {
            ForEach(1...5, id: \.self) { number in
                Text("Item \(number)")
            }
        }
    }
}
