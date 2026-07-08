import SwiftUI

/// Lets the user type a hex or RGB value and shows the 3 nearest material colors.
struct ColorFinderView: View {
    let onCopy: (String) -> Void

    @State private var input: String = ""
    @State private var parsed: RGB?
    @State private var matches: [ColorMatch] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                inputSection

                if let parsed {
                    inputPreview(parsed)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }

                if !matches.isEmpty {
                    Text("3 Nearest Material Colors")
                        .font(.headline)
                    ForEach(matches) { match in
                        matchRow(match)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: prefillFromClipboard)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter a color")
                .font(.headline)
            Text("Accepts hex (#F44336, F44336, #F00) or RGB (rgb(244, 67, 54) or 244, 67, 54).")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("#F44336 or 244, 67, 54", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: input) { find() }
                if !input.isEmpty {
                    Button {
                        input = ""
                        find()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func inputPreview(_ rgb: RGB) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: rgb.hexString))
                .frame(width: 56, height: 56)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            VStack(alignment: .leading, spacing: 2) {
                Text("Your color").font(.subheadline.weight(.semibold))
                Text(rgb.hexString).font(.system(.body, design: .monospaced))
                Text("rgb(\(rgb.r), \(rgb.g), \(rgb.b))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }

    private func matchRow(_ match: ColorMatch) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(match.swatch.color)
                .frame(width: 56, height: 56)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            VStack(alignment: .leading, spacing: 2) {
                Text(match.swatch.displayName).font(.body.weight(.semibold))
                Text(match.swatch.hex).font(.system(.callout, design: .monospaced))
                Text("ΔE \(String(format: "%.1f", match.distance))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Clipboard.copy(match.swatch.hex)
                onCopy("Copied \(match.swatch.hex)")
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
    }

    /// When the tab appears, if the clipboard holds a valid color and the
    /// field is empty, drop it in and search automatically.
    private func prefillFromClipboard() {
        guard input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let clip = Clipboard.string() else { return }
        let candidate = clip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty, RGB.parse(candidate) != nil else { return }
        input = candidate // triggers onChange -> find()
    }

    private func find() {
        errorMessage = nil
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            parsed = nil
            matches = []
            return
        }
        guard let rgb = RGB.parse(input) else {
            parsed = nil
            matches = []
            errorMessage = "Could not read that color. Try a hex like #F44336 or RGB like 244, 67, 54."
            return
        }
        parsed = rgb
        matches = ColorFinder.nearest(to: rgb, count: 3)
    }
}
