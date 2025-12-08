import SwiftUI
import Combine

/// Timer de descanso para entrenamientos
struct RestTimer: View {
    let duration: TimeInterval // Duración en segundos
    let onComplete: () -> Void
    let onCancel: (() -> Void)?
    
    @State private var timeRemaining: TimeInterval
    @State private var timer: Timer?
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    
    init(duration: TimeInterval, onComplete: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.duration = duration
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._timeRemaining = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Título
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text(NSLocalizedString("rest.timer.title", comment: "Rest Timer"))
                    .font(.headline)
                Spacer()
                if onCancel != nil {
                    Button(action: {
                        stopTimer()
                        onCancel?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Tiempo restante (grande)
            Text(formatTime(timeRemaining))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timeRemaining <= 10 ? .red : .primary)
            
            // Barra de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(timeRemaining <= 10 ? .red : .orange)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.linear, value: timeRemaining)
                }
            }
            .frame(height: 8)
            
            // Controles
            HStack(spacing: 16) {
                if !isRunning && !isPaused {
                    Button(action: startTimer) {
                        Label(NSLocalizedString("rest.timer.start", comment: "Start"), systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    if isPaused {
                        Button(action: resumeTimer) {
                            Label(NSLocalizedString("rest.timer.resume", comment: "Resume"), systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Button(action: pauseTimer) {
                            Label(NSLocalizedString("rest.timer.pause", comment: "Pause"), systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.orange.opacity(0.7))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button(action: resetTimer) {
                        Label(NSLocalizedString("rest.timer.reset", comment: "Reset"), systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.secondary.opacity(0.2))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onDisappear {
            stopTimer()
        }
    }
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return 1.0 - (timeRemaining / duration)
    }
    
    private func startTimer() {
        isRunning = true
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                onComplete()
            }
        }
    }
    
    private func pauseTimer() {
        isPaused = true
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeTimer() {
        isPaused = false
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                onComplete()
            }
        }
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = duration
        isPaused = false
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

/// Vista compacta del timer (para usar en listas)
struct CompactRestTimer: View {
    let duration: TimeInterval
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text(formatTime(duration))
                    .font(.subheadline)
                    .monospacedDigit()
                Text(NSLocalizedString("rest.timer.start", comment: "Start"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.orange.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return String(format: "%ds", secs)
    }
}
