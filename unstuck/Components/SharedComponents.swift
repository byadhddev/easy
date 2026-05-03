import SwiftUI

// MARK: - Primary CTA Button
// Amber, full-width, pill-shaped. The main action in any screen.

struct AppPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appCTA)
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(isEnabled ? Color.appAmber : Color.appAmberDim)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.pill))
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .animation(AppAnimation.fadeIn, value: isEnabled)
    }
}

// MARK: - Ghost Button
// Text-only, muted. For "Not ready yet" and secondary actions with no shame attached.

struct AppGhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appLabel)
                .foregroundStyle(Color.appTextDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quest Card
// Compact preview card shown on Home if an active quest exists.

struct QuestCardPreview: View {
    let quest: Quest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.appAmber)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(AppCopy.Home.acceptedQuestLabel)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextDim)

                    Text(quest.stepTitle)
                        .font(.appLabel)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appTextDim)
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Divider
struct AppDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow Layout (for category pills)
// Wraps pill chips to new lines automatically.

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.maxHeight }.reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = item.sizeThatFits(.unspecified)
                item.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.maxHeight + spacing
        }
    }

    private struct Row {
        var items: [LayoutSubview] = []
        var maxHeight: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !current.items.isEmpty {
                rows.append(current)
                current = Row()
                currentWidth = 0
            }
            current.items.append(subview)
            current.maxHeight = max(current.maxHeight, size.height)
            currentWidth += size.width + spacing
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}
