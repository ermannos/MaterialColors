import SwiftUI

/// Shows the material palette with a compact vertical tab bar of color
/// families on the left; the selected family's shades fill the main area.
/// Clicking a swatch copies its hex value to the clipboard.
struct ColorGridView: View {
    let onCopy: (String) -> Void

    @State private var selectedFamilyID: MaterialFamily.ID = MaterialPalette.families[0].id

    private var families: [MaterialFamily] { MaterialPalette.families }

    private var selectedFamily: MaterialFamily {
        families.first { $0.id == selectedFamilyID } ?? families[0]
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            shadeArea
        }
    }

    // MARK: Vertical tab bar

    private var sidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(families) { family in
                        FamilyTab(
                            family: family,
                            isSelected: family.id == selectedFamilyID
                        ) {
                            selectedFamilyID = family.id
                        }
                    }
                }
                .padding(6)
            }
        }
        .frame(width: 190)
        .background(.background.secondary)
    }

    // MARK: Selected family shades

    private var shadeArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedFamily.representative.color)
                    .frame(width: 24, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                Text(selectedFamily.name)
                    .font(.headline)
                Spacer()
                Text("\(selectedFamily.swatches.count) shades")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Divider()
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(selectedFamily.swatches) { swatch in
                        ShadeRow(swatch: swatch, onCopy: onCopy)
                    }
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A single row in the vertical family tab bar.
struct FamilyTab: View {
    let family: MaterialFamily
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(family.representative.color)
                    .frame(width: 18, height: 18)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.black.opacity(0.12)))
                Text(family.name)
                    .font(.callout)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.18)
                                     : (hovering ? Color.primary.opacity(0.06) : .clear))
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 3)
                        .padding(.vertical, 4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// A single tappable color row in the vertical shade list.
struct ShadeRow: View {
    let swatch: MaterialSwatch
    let onCopy: (String) -> Void

    @State private var hovering = false

    var body: some View {
        Button {
            Clipboard.copy(swatch.hex)
            onCopy("Copied \(swatch.hex)")
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(swatch.color)
                    .frame(width: 22, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.primary.opacity(0.12)))
                Text(swatch.shadeName)
                    .font(.callout.weight(.semibold))
                    .frame(width: 46, alignment: .leading)
                Text(swatch.hex)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(hovering ? 1 : 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hovering ? Color.primary.opacity(0.06) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Click to copy \(swatch.displayName) (\(swatch.hex))")
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
