import SwiftUI

struct ContentUnavailableView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("暂无内容")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("这里还没有任何内容")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}