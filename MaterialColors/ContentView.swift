import SwiftUI

struct ContentView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case palette = "Palette"
        case finder = "Find Nearest"
        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .palette
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(12)
            .frame(maxWidth: 360)

            Divider()

            Group {
                switch selectedTab {
                case .palette:
                    ColorGridView(onCopy: showToast)
                case .finder:
                    ColorFinderView(onCopy: showToast)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thickMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.quaternary))
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: toast)
    }

    private func showToast(_ message: String) {
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { if toast == message { toast = nil } }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 640)
}
