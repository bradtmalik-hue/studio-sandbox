// 基础组件：本 App 的版式骨架（grid / 圆角 20 / both / 标题 large / 行 index）。
// 页面只用这些拼，不要从零画卡片和按钮。命名带 App 前缀，避免多个 App 出现同名符号。
import SwiftUI

// MARK: - 页面骨架
struct AppScreen<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.s5) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: AppTheme.s1) {
                            Text(title).font(AppTheme.titleFont).foregroundStyle(AppTheme.text)
                            if let subtitle {
                                Text(subtitle).font(AppTheme.fontLabel).foregroundStyle(AppTheme.dim)
                            }
                        }
                        Spacer(minLength: AppTheme.s3)
                        if let trailing { trailing }
                    }
                    content()
                }
                .padding(.horizontal, AppTheme.s5)
                .padding(.top, AppTheme.s4)
                .padding(.bottom, AppTheme.s10)
            }
        }
        .preferredColorScheme(AppTheme.colorScheme)
    }
}

// MARK: - 卡片
struct AppCard<Content: View>: View {
    var padding: CGFloat = AppTheme.s4
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.rCard, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.rCard, style: .continuous)
                .stroke(AppTheme.stroke, lineWidth: AppTheme.hasStroke ? 1 : 0))
            .shadow(color: AppTheme.hasShadow ? AppTheme.shadowColor : .clear,
                    radius: AppTheme.hasShadow ? AppTheme.shadowRadius : 0,
                    x: 0, y: AppTheme.hasShadow ? AppTheme.shadowY : 0)
    }
}

// MARK: - 主按钮
struct AppPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.s2) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(AppTheme.fontSection)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s3 + 2)
            .background(enabled ? AppTheme.accent : AppTheme.surfaceAlt,
                        in: RoundedRectangle(cornerRadius: AppTheme.rCard, style: .continuous))
            .foregroundStyle(enabled ? AppTheme.bg : AppTheme.dim)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - 列表行
struct AppRowItem: View {
    var icon: String? = nil
    var leading: String? = nil
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    var tint: Color? = nil

    var body: some View {
        HStack(spacing: AppTheme.s3) {
            Text(leading ?? "")
                .font(AppTheme.fontLabel)
                .foregroundStyle(AppTheme.dim)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppTheme.fontBody).foregroundStyle(AppTheme.text)
                if let subtitle {
                    Text(subtitle).font(AppTheme.fontCaption).foregroundStyle(AppTheme.dim)
                }
            }
            Spacer(minLength: AppTheme.s2)
            if let trailing {
                Text(trailing).font(AppTheme.fontLabel).foregroundStyle(AppTheme.dim)
            }
        }
        .padding(.vertical, AppTheme.s3)
        .contentShape(Rectangle())
    }
}

// MARK: - 数字块
struct AppStatTile: View {
    let value: String
    let label: String
    var hint: String? = nil

    var body: some View {
        AppCard(padding: AppTheme.s4) {
            VStack(alignment: .leading, spacing: AppTheme.s1) {
                Text(value).font(AppTheme.fontNumber).foregroundStyle(AppTheme.text)
                Text(label).font(AppTheme.fontLabel).foregroundStyle(AppTheme.dim)
                if let hint {
                    Text(hint).font(AppTheme.fontCaption).foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - 空状态
struct AppEmptyState: View {
    var icon: String = "tray"
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: AppTheme.s3) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(AppTheme.dim)
            Text(title).font(AppTheme.fontSection).foregroundStyle(AppTheme.text)
            if let message {
                Text(message).font(AppTheme.fontLabel).foregroundStyle(AppTheme.dim)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.s10)
    }
}

// MARK: - 小标签
struct AppBadge: View {
    let text: String
    var tone: Color? = nil

    var body: some View {
        Text(text)
            .font(AppTheme.fontCaption)
            .padding(.horizontal, AppTheme.s2 + 2)
            .padding(.vertical, 3)
            .background((tone ?? AppTheme.accent).opacity(0.16), in: Capsule())
            .foregroundStyle(tone ?? AppTheme.accent)
    }
}

// MARK: - 表单行
struct AppFieldRow: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s1) {
            Text(label).font(AppTheme.fontCaption).foregroundStyle(AppTheme.dim)
            TextField(placeholder, text: $text)
                .font(AppTheme.fontBody)
                .keyboardType(keyboard)
                .padding(.horizontal, AppTheme.s3)
                .padding(.vertical, AppTheme.s3)
                .background(AppTheme.surfaceAlt,
                            in: RoundedRectangle(cornerRadius: AppTheme.rSmall, style: .continuous))
        }
    }
}

// MARK: - 分区标题
struct AppSectionHeader: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(AppTheme.fontCaption)
                .tracking(1.1)
                .foregroundStyle(AppTheme.dim)
            Spacer()
            if let trailing {
                Text(trailing).font(AppTheme.fontCaption).foregroundStyle(AppTheme.accent)
            }
        }
    }
}
