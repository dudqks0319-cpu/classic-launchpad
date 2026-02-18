import ClassicLaunchCore
import SwiftUI

struct AppTileView: View {
    let app: InstalledApp
    let selected: Bool
    let editing: Bool
    let onActivate: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: IconProvider.shared.icon(forAppPath: app.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)

            Text(app.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(tileBackground)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            onActivate()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    @ViewBuilder
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.white.opacity(selected ? 0.25 : isHovering ? 0.15 : 0.08))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(selected ? 0.65 : 0.15), lineWidth: selected ? 1.8 : 1)
            }
    }
}
