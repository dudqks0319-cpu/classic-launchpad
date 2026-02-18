import ClassicLaunchCore
import SwiftUI

struct FolderTileView: View {
    let folder: DisplayFolder
    let onOpen: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.18))
                .frame(width: 66, height: 66)
                .overlay {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(Array(folder.apps.prefix(4))) { app in
                            Image(nsImage: IconProvider.shared.icon(forAppPath: app.path))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                    .padding(7)
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("\(folder.apps.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(4)
                }

            Text(folder.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(isHovering ? 0.14 : 0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                }
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            onOpen()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
