import SwiftUI

struct AppLocationView: View {
    private static var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text(Self.isChinese ? "位置" : "Location")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(Self.isChinese ? "当前没有可显示的位置信息。" : "No location information to display.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle(Self.isChinese ? "位置" : "Location")
    }
}

#Preview {
    NavigationStack {
        AppLocationView()
    }
}