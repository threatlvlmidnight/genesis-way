import AVFoundation
import Speech
import SwiftUI
import UIKit

struct DumpScreen: View {
    @EnvironmentObject private var store: GenesisStore
    @State private var input = ""
    @FocusState private var isInputFocused: Bool
    @StateObject private var voice = VoiceDumpController()
    @State private var wasRecording = false
    @State private var voiceStatusMessage: String?
    @State private var hasDeferredFocus = false
    @State private var keyboardVisible = false

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    TextField("What is occupying your mind right now?", text: $input)
                        .submitLabel(.done)
                        .focused($isInputFocused)
                        .onSubmit {
                            addTypedDumpItem()
                        }
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(GWTheme.textPrimary)

                    Button("+") {
                        addTypedDumpItem()
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "1a1208"))
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: [GWTheme.gold, GWTheme.goldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        voice.toggleRecording()
                    } label: {
                        Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(voice.isRecording ? Color(hex: "5a0f0f") : Color(hex: "1a1208"))
                            .frame(width: 44, height: 44)
                            .background(voice.isRecording ? Color(hex: "e08a8a") : GWTheme.gold.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                if !voice.transcript.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Capture")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                                .textCase(.uppercase)

                            Text(voice.transcript)
                                .font(.system(size: 12))
                                .foregroundStyle(GWTheme.textMuted)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 10) {
                                Button("Clear") {
                                    voice.clearTranscript()
                                    voiceStatusMessage = nil
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GWTheme.textGhost)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if let error = voice.errorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "c07060"))
                }

                if let status = voiceStatusMessage {
                    Text(status)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GWTheme.gold)
                }

                if store.dumpItems.isEmpty {
                    VStack(spacing: 8) {
                        Text("Your list is clear")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GWTheme.textMuted)
                        Text("Start dumping everything you are carrying.")
                            .font(.system(size: 12))
                            .foregroundStyle(GWTheme.textGhost)
                    }
                    .padding(.top, 28)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Captured — \(store.dumpItems.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                                .padding(.bottom, 6)

                            ForEach(store.dumpItems) { item in
                                HStack(spacing: 10) {
                                    Circle().fill(GWTheme.gold.opacity(0.35)).frame(width: 6, height: 6)
                                    Text(item.text)
                                        .font(.system(size: 13))
                                        .foregroundStyle(GWTheme.textMuted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Button("×") { store.removeDumpItem(id: item.id) }
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(GWTheme.textGhost)
                                }
                                .padding(.vertical, 10)
                                Divider().overlay(GWTheme.gold.opacity(0.07))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(GWTheme.background.ignoresSafeArea())
        .onAppear {
            guard !store.shouldShowGuidedSetup else { return }
            guard !hasDeferredFocus else { return }
            hasDeferredFocus = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isInputFocused = true
            }
        }
        .onChange(of: store.shouldShowGuidedSetup) { _, shouldShow in
            guard !shouldShow else {
                isInputFocused = false
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                isInputFocused = true
            }
        }
        .onDisappear {
            isInputFocused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
        .onChange(of: voice.isRecording) { _, isRecording in
            if wasRecording && !isRecording {
                parseTranscriptIntoDumpItems()
            }
            wasRecording = isRecording
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GWTheme.gold)
                .padding(.vertical, 6)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if keyboardVisible {
                HStack {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GWTheme.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.92))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .background(Color.black.opacity(0.35))
            }
        }
    }

    private func aiParseDumpItems(from raw: String) -> [String] {
        let normalized = raw
            .replacingOccurrences(of: "\n", with: ". ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        let splitPattern = #"(?:[\.;,]|\b(?:and|then|also|plus|next)\b)"#
        let tokenized = normalized.replacingOccurrences(of: splitPattern, with: "|", options: .regularExpression)

        return tokenized
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { item in
                let lowered = item.lowercased()
                if lowered.hasPrefix("and ") {
                    return String(item.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                }
                if lowered.hasPrefix("also ") {
                    return String(item.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                }
                return item
            }
            .filter { $0.count >= 3 }
    }

    private func parseTranscriptIntoDumpItems() {
        let parsed = aiParseDumpItems(from: voice.transcript)
        guard !parsed.isEmpty else {
            voiceStatusMessage = voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Could not detect separate items. Try pausing between tasks."
            return
        }

        for item in parsed {
            store.addDumpItem(item)
        }

        voiceStatusMessage = "Added \(parsed.count) item\(parsed.count == 1 ? "" : "s") from voice capture."
        voice.clearTranscript()
    }

    private func addTypedDumpItem() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isInputFocused = false
            return
        }
        store.addDumpItem(trimmed)
        input = ""
        isInputFocused = true
        GWHaptics.light()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Step 1 of 3")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GWTheme.textGhost)
            Text("Dump It")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(GWTheme.textPrimary)
            Text("Get everything out of your head. Don't filter.")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

@MainActor
final class VoiceDumpController: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            requestAndStart()
        }
    }

    func clearTranscript() {
        transcript = ""
    }

    private func requestAndStart() {
        errorMessage = nil

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self else { return }

            DispatchQueue.main.async {
                guard status == .authorized else {
                    self.errorMessage = "Speech permission denied. Enable Speech Recognition in Settings."
                    return
                }

                if #available(iOS 17.0, *) {
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            guard granted else {
                                self.errorMessage = "Microphone permission denied. Enable Microphone in Settings."
                                return
                            }
                            self.startRecording()
                        }
                    }
                } else {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            guard granted else {
                                self.errorMessage = "Microphone permission denied. Enable Microphone in Settings."
                                return
                            }
                            self.startRecording()
                        }
                    }
                }
            }
        }
    }

    private func startRecording() {
        guard !audioEngine.isRunning else { return }
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer is currently unavailable."
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            errorMessage = "Unable to initialize speech request."
            return
        }
        recognitionRequest.shouldReportPartialResults = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            transcript = ""
            isRecording = true

            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self else { return }

                if let result {
                    DispatchQueue.main.async {
                        self.transcript = result.bestTranscription.formattedString
                    }
                }

                if error != nil || (result?.isFinal ?? false) {
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            stopRecording()
        }
    }

    private func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore deactivation errors in UI flow.
        }
    }
}
