import Foundation

struct AppPercentilePoint: Identifiable {
    let ageMonths: Double
    let value: Double

    var id: Double { ageMonths }
}

struct AppPercentileSeries: Identifiable {
    let percentile: Double
    let points: [AppPercentilePoint]

    var id: Double { percentile }
    var title: String { "P\(Int(percentile))" }
}

enum AppPercentileData {
    static let ageMonths: [Double] = [0, 2, 4, 6, 9, 12, 18, 24, 36, 48, 60]
    static let chartPercentiles: [Double] = [3, 15, 50, 85, 97]

    private static func series(_ percentile: Double, _ values: [Double]) -> AppPercentileSeries {
        let points = zip(ageMonths, values).map { pair in
            AppPercentilePoint(ageMonths: pair.0, value: pair.1)
        }
        return AppPercentileSeries(percentile: percentile, points: points)
    }

    static let heightBoys: [AppPercentileSeries] = [
        series(3, [46.1, 54.3, 59.6, 63.1, 67.3, 70.8, 76.8, 82.2, 90.1, 96.9, 103.2]),
        series(15, [47.8, 56.1, 61.5, 65.1, 69.4, 73.0, 79.3, 84.7, 92.8, 99.8, 106.3]),
        series(50, [49.9, 58.4, 63.9, 67.6, 72.0, 75.7, 82.3, 87.8, 96.1, 103.3, 110.0]),
        series(85, [52.0, 60.7, 66.3, 70.1, 74.6, 78.4, 85.3, 90.9, 99.4, 106.8, 113.7]),
        series(97, [53.7, 62.5, 68.2, 72.1, 76.7, 80.6, 87.8, 93.4, 102.1, 109.7, 116.8])
    ]

    static let heightGirls: [AppPercentileSeries] = [
        series(3, [45.3, 53.2, 57.8, 61.2, 65.4, 69.1, 75.4, 80.8, 89.1, 96.3, 102.8]),
        series(15, [47.0, 54.9, 59.7, 63.2, 67.5, 71.3, 77.8, 83.3, 91.8, 99.2, 105.8]),
        series(50, [49.1, 57.1, 62.1, 65.7, 70.1, 74.0, 80.7, 86.4, 95.1, 102.7, 109.4]),
        series(85, [51.2, 59.3, 64.5, 68.2, 72.7, 76.7, 83.6, 89.5, 98.4, 106.2, 113.0]),
        series(97, [52.9, 61.1, 66.4, 70.2, 74.8, 78.9, 86.0, 92.0, 101.1, 109.1, 116.1])
    ]
}