import SwiftUI

struct MenuContentView: View {
    @ObservedObject var windowManager = WindowManager.shared
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if windowManager.windows.isEmpty {
                Text("No windows found")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(windowManager.windows) { window in
                            WindowRow(window: window)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 360)
            }

            Divider()

            footer
        }
        .frame(width: 320)
        .onAppear { windowManager.refresh() }
    }

    private var header: some View {
        HStack {
            Text("Open Windows")
                .font(.headline)
            Spacer()
            Button {
                windowManager.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var footer: some View {
        HStack {
            Button {
                onOpenSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Quit") {
                onQuit()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct WindowRow: View {
    @ObservedObject var windowManager = WindowManager.shared
    let window: ManagedWindow

    private var isFloating: Bool { windowManager.isFloating(window.id) }
    private var priority: Int? { windowManager.priority(of: window.id) }

    var body: some View {
        Button {
            windowManager.toggleFloating(window)
        } label: {
            HStack(spacing: 8) {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "app")
                        .frame(width: 20, height: 20)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(window.displayTitle)
                        .lineLimit(1)
                        .font(.callout)
                    Text(window.ownerName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let priority {
                    Text("#\(priority)")
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }

                Image(systemName: isFloating ? "pin.fill" : "pin")
                    .foregroundStyle(isFloating ? .blue : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isFloating ? Color.blue.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 6)
    }
}
