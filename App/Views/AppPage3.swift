import SwiftUI

struct AppPage3View: View {
    let settings: AppSettings
    let data: DemoSeed?

    var body: some View {
        List {
            AppPage3StepperRow(
                title: "每日任务上限",
                subtitle: String(settings.maxDailyTodos),
                range: 1...10
            )
            AppPage3TextFieldRow(
                title: "默认分类",
                placeholder: "输入分类"
            )
            AppPage3ToggleRow(
                title: "提醒",
                subtitle: settings.reminderEnabled ? "已开启" : "已关闭"
            )
            AppPage3DateRow(
                title: "提醒时间"
            )
        }
    }
}

struct AppPage3StepperRow: View {
    let title: String
    let subtitle: String
    let range: ClosedRange<Int>

    @State private var value: Int

    init(title: String, subtitle: String, range: ClosedRange<Int>) {
        self.title = title
        self.subtitle = subtitle
        self.range = range
        _value = State(initialValue: range.lowerBound)
    }

    var body: some View {
        Stepper(value: $value, in: range) {
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AppPage3TextFieldRow: View {
    let title: String
    let placeholder: String

    @State private var text = ""

    var body: some View {
        HStack {
            Text(title)
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct AppPage3ToggleRow: View {
    let title: String
    let subtitle: String

    @State private var isOn = false

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AppPage3DateRow: View {
    let title: String

    @State private var date = Date()

    var body: some View {
        DatePicker(title, selection: $date, displayedComponents: .hourAndMinute)
    }
}