import SwiftUI

struct AppGrowthChartView: View {
    private let data: [Double] = [12, 18, 25, 22, 35, 48, 62, 78, 95, 120]
    private let lineColor: Color = .blue

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minValue = data.min() ?? 0
            let maxValue = data.max() ?? 1
            let range = max(maxValue - minValue, 1)

            ZStack {
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let y = height - CGFloat((value - minValue) / range) * height * 0.8 - height * 0.1
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [lineColor.opacity(0.25), lineColor.opacity(0.0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                        let y = height - CGFloat((value - minValue) / range) * height * 0.8 - height * 0.1
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                ForEach(data.indices, id: \.self) { index in
                    let x = width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let y = height - CGFloat((data[index] - minValue) / range) * height * 0.8 - height * 0.1
                    Circle()
                        .fill(lineColor)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
        .frame(height: 200)
    }
}