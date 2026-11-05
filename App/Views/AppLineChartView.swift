import SwiftUI

struct AppLineChartView: View {
    private let data: [Double] = [12, 18, 15, 22, 28, 24, 35, 30, 40, 38, 45, 50]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minValue = data.min() ?? 0
            let maxValue = data.max() ?? 1
            let range = max(maxValue - minValue, 1)
            let stepX = data.count > 1 ? width / CGFloat(data.count - 1) : width
            let points = data.enumerated().map { index, value -> CGPoint in
                let x = data.count > 1 ? CGFloat(index) * stepX : width / 2
                let y = height - CGFloat((value - minValue) / range) * height
                return CGPoint(x: x, y: y)
            }

            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    let y = height * CGFloat(i) / 3
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)

                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                        .position(points[index])
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}