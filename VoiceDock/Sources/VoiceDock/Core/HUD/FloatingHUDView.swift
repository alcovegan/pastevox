import SwiftUI

struct FloatingHUDView: View {
    @ObservedObject var controller: FloatingHUDController
    @ObservedObject private var audioRecorder = AudioRecorder.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            if controller.state == .hidden {
                collapsedBar
            } else if controller.state == .listening {
                listeningBar
            } else {
                compactStatusBar
            }
        }
        .frame(width: 420, height: 72, alignment: .bottom)
        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: controller.state)
    }

    private var collapsedBar: some View {
        Capsule()
            .fill(.white.opacity(0.42))
            .frame(width: 132, height: 6)
            .shadow(color: .black.opacity(0.28), radius: 5, y: 2)
            .padding(.vertical, 7)
            .frame(width: 160, height: 22)
    }

    private var listeningBar: some View {
        HStack(spacing: 12) {
            stateDot
            VStack(alignment: .leading, spacing: 1) {
                Text("Listening")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(textColor)
                Text(AppSettings.shared.promptMode.shortTitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(textColor.opacity(0.7))
            }
            .frame(width: 76, alignment: .leading)
            VoiceWaveformView(color: .cyan, levels: audioRecorder.waveformLevels)
                .frame(width: 220, height: 24)
        }
        .padding(.horizontal, 16)
        .frame(width: 380, height: 44)
        .background(hudBackground, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
    }

    private var compactStatusBar: some View {
        HStack(spacing: 10) {
            stateDot
            Text(controller.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(textColor)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(textColor.opacity(0.72))
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .frame(width: 300, height: 44)
        .background(hudBackground, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
    }

    private var stateDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 9, height: 9)
    }

    private var subtitle: String {
        switch controller.state {
        case .hidden: ""
        case .listening: ""
        case .transcribing: "processing"
        case .pasted: "done"
        case .error: "check Settings"
        case .modeChanged: "selected"
        }
    }

    private var textColor: Color {
        Color.white.opacity(0.94)
    }

    private var hudBackground: Color {
        Color(red: 0.07, green: 0.11, blue: 0.18).opacity(0.88)
    }

    private var dotColor: Color {
        switch controller.state {
        case .hidden: .secondary
        case .listening: .cyan
        case .transcribing: .purple
        case .pasted: .green
        case .error: .red
        case .modeChanged: .cyan
        }
    }
}

private struct VoiceWaveformView: View {
    let color: Color
    let levels: [Double]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                let clamped = max(0.06, min(1.0, level))
                let height = 5 + CGFloat(clamped) * 25
                Capsule()
                    .fill(color.opacity(0.34 + clamped * 0.56))
                    .frame(width: 4, height: height)
            }
        }
        .animation(.linear(duration: 0.06), value: levels)
    }
}
