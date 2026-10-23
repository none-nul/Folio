import AppKit
import Observation
import SwiftUI

/// "重新检测" in a settings section header: the circular-arrows symbol turns while the check runs, then the
/// result ("找到 3 个智能体") shows beside the button for a few seconds, so a click always visibly does something.
struct RedetectButton: View {
    let isChecking: Bool
    let result: String?
    var help = String(localized: "重新检测")
    let action: () -> Void

    /// The arrow-head variant is new in macOS 15.
    private static var symbol: String {
        if #available(macOS 15, *) { "arrow.trianglehead.2.clockwise.rotate.90" } else { "arrow.clockwise" }
    }

    var body: some View {
        HStack(spacing: 8) {
            if let result {
                Label(result, systemImage: "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)))
            }
            Button(action: action) {
                Label(isChecking ? String(localized: "正在检测…") : String(localized: "重新检测"), systemImage: Self.symbol)
                    .spinning(isChecking)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isChecking)
            .help(help)
        }
        .animation(.smooth(duration: 0.25), value: result)
        .animation(.smooth(duration: 0.25), value: isChecking)
    }
}

/// Drives a `RedetectButton`: runs the check for at least a moment (an instant check reads as "nothing
/// happened"), then shows its one-line result for three seconds.
@Observable
final class RedetectState {
    private(set) var isChecking = false
    private(set) var result: String?
    private var generation = 0

    func run(_ check: @escaping () async -> String) {
        guard !isChecking else { return }
        isChecking = true
        result = nil
        Task {
            let started = ContinuousClock.now
            let text = await check()
            try? await Task.sleep(until: started + .milliseconds(600))
            isChecking = false
            result = text
            generation += 1
            let current = generation
            try? await Task.sleep(for: .seconds(3))
            if current == generation { result = nil }
        }
    }
}

/// A coloured status pill ("● 已启用"), readable at a glance unlike a line of grey caption text.
struct StatusBadge: View {
    enum Tone { case positive, attention, neutral, info }
    let text: String
    let tone: Tone

    private var color: Color {
        switch tone {
        case .positive: .green
        case .attention: .orange
        case .neutral: .secondary
        case .info: .blue
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.callout.weight(.medium))
        }
        .foregroundStyle(tone == .neutral ? Color.secondary : color)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(color.opacity(0.13), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.28), lineWidth: 0.5))
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

/// Records a new highlight shortcut. Click, press the keys, Esc cancels.
struct HighlightShortcutControls: View {
    @Bindable var settings: AppSettings
    @State private var recording = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    recording.toggle()
                    if recording { error = nil }
                } label: {
                    Text(recording ? String(localized: "请按下快捷键") : settings.highlightShortcut.display)
                        .font(.body.weight(.medium))
                        .frame(minWidth: 120)
                }
                .buttonStyle(.bordered)
                .overlay {
                    if recording {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.accentColor, lineWidth: 2)
                    }
                }
                .accessibilityIdentifier("highlightShortcutRecorder")
                .accessibilityLabel(Text("高亮快捷键"))
                .accessibilityValue(Text(recording ? String(localized: "请按下快捷键") : settings.highlightShortcut.display))
                .help(Text(recording ? String(localized: "按下新的快捷键，Esc 取消") : String(localized: "按下以设置高亮快捷键")))
                Button("恢复默认") {
                    recording = false
                    error = nil
                    settings.highlightShortcut = .default
                }
                .disabled(settings.highlightShortcut == .default)
                .accessibilityIdentifier("highlightShortcutReset")
            }
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 260, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .background {
            ShortcutCapture(isRecording: recording) { event in
                handle(event)
            }
        }
        .onDisappear { recording = false }
    }

    private func handle(_ event: NSEvent) {
        switch HighlightShortcut.capture(event) {
        case .cancelled:
            recording = false
        case .rejected(let message):
            error = message
            NSSound.beep()
        case .success(let shortcut):
            if let title = ReaderMenus.reservedTitle(matching: shortcut) {
                error = String(format: String(localized: "这个快捷键已被「%@」使用"), title)
                NSSound.beep()
                return
            }
            error = nil
            recording = false
            settings.highlightShortcut = shortcut
        }
    }
}

/// Result of one key press while the recorder is armed.
extension HighlightShortcut {
    enum Capture {
        case success(HighlightShortcut)
        case cancelled
        case rejected(String)
    }

    static func capture(_ event: NSEvent) -> Capture {
        if event.keyCode == 53 { return .cancelled }
        let modifiers = Modifiers(rawValue: event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue)
        guard modifiers.contains(.command) || modifiers.contains(.control) else {
            return .rejected(String(localized: "快捷键需要包含 ⌘ 或 ⌃"))
        }
        let unmodified = event.characters(byApplyingModifiers: []) ?? ""
        guard let key = key(forKeyCode: event.keyCode, unmodified: unmodified) else {
            return .rejected(String(localized: "这个按键不能用作快捷键"))
        }
        let shortcut = HighlightShortcut(key: key, modifiers: modifiers)
        guard shortcut.isUsable else {
            return .rejected(String(localized: "快捷键需要包含 ⌘ 或 ⌃"))
        }
        return .success(shortcut)
    }
}

/// Swallows key-down events while recording. The menu bar would otherwise perform ⌘ shortcuts
/// before a view could see them.
private struct ShortcutCapture: NSViewRepresentable {
    var isRecording: Bool
    var onEvent: (NSEvent) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ view: CaptureView, context: Context) {
        context.coordinator.onEvent = onEvent
        view.setRecording(isRecording)
    }

    static func dismantleNSView(_ view: CaptureView, coordinator: Coordinator) {
        view.setRecording(false)
    }

    final class Coordinator {
        var onEvent: (NSEvent) -> Void = { _ in }
    }

    final class CaptureView: NSView {
        var coordinator: Coordinator?
        private var recording = false
        private var monitor: Any?
        private let bridge = Bridge()

        func setRecording(_ recording: Bool) {
            guard recording != self.recording else { return }
            self.recording = recording
            bridge.view = self
            if recording { installMonitor() } else { removeMonitor() }
        }

        private func installMonitor() {
            guard monitor == nil else { return }
            let bridge = bridge
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // assumeIsolated can only return a Sendable value, and NSEvent's Sendable
                // conformance is unavailable. The monitor itself runs on the main thread.
                let pointer = Unmanaged.passUnretained(event).toOpaque()
                let swallow = MainActor.assumeIsolated { () -> Bool in
                    let event = Unmanaged<NSEvent>.fromOpaque(pointer).takeUnretainedValue()
                    guard let view = bridge.view, view.recording else { return false }
                    if event.isARepeat { return true }
                    view.coordinator?.onEvent(event)
                    return true
                }
                return swallow ? nil : event
            }
        }

        private func removeMonitor() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }

    nonisolated final class Bridge: @unchecked Sendable {
        nonisolated(unsafe) weak var view: CaptureView?
    }
}

private extension View {
    /// The circular arrows turn while a check runs (pulse before macOS 15, which has no rotate effect).
    @ViewBuilder func spinning(_ active: Bool) -> some View {
        if #available(macOS 15, *) {
            symbolEffect(.rotate, options: .repeat(.continuous), isActive: active)
        } else {
            symbolEffect(.pulse, options: .repeating, isActive: active)
        }
    }
}
