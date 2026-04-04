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
    @State private var editingItemId: UUID? = nil
    @State private var editingText = ""
    @FocusState private var isEditFocused: Bool

    private var selectedDay: Date {
        store.activePlanningDay
    }

    private var selectedDayBinding: Binding<Date> {
        Binding(
            get: { store.activePlanningDay },
            set: { store.setActivePlanningDay($0) }
        )
    }

    private var dayDumpItems: [DumpItem] {
        store.dumpItems(for: selectedDay)
    }

    private var isViewingPastDay: Bool {
        let calendar = Calendar.current
        let selected = calendar.startOfDay(for: selectedDay)
        let today = calendar.startOfDay(for: Date())
        return selected < today
    }

    private var carriedItems: [DumpItem] {
        dayDumpItems.filter { $0.carriedOver == true }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(spacing: 10) {
                DatePicker("Day", selection: selectedDayBinding, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)

                Button("Today") {
                    store.setActivePlanningDayToToday()
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isViewingPastDay ? GWTheme.gold : Color(hex: "1a1208"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isViewingPastDay ? Color.white.opacity(0.08) : GWTheme.gold)
                .clipShape(Capsule())
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            VStack(spacing: 14) {
                if isViewingPastDay {
                    GlassCard {
                        Text("Past days are read-only. Switch to today or a future day to add or edit items.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GWTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

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
                        .disabled(isViewingPastDay)

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
                    .disabled(isViewingPastDay)

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
                            .disabled(isViewingPastDay)
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

                if dayDumpItems.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How to Dump It")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                                .textCase(.uppercase)

                            ForEach([
                                ("1", "Empty your head fully", "Type every task, worry, idea, or obligation — Work, Home, Hobby, School. All of it."),
                                ("2", "Don't filter yet", "No sorting, no prioritising. Capture first, judge later. The goal is an empty mind."),
                                ("3", "Tap Shape when done", "Once everything is out, head to Shape to run each item through the five filters.")
                            ], id: \.0) { num, title, detail in
                                HStack(alignment: .top, spacing: 10) {
                                    Text(num)
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(GWTheme.gold)
                                        .frame(width: 18, alignment: .center)
                                        .padding(.top, 1)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(title)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(GWTheme.textPrimary)
                                        Text(detail)
                                            .font(.system(size: 12))
                                            .foregroundStyle(GWTheme.textMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if !carriedItems.isEmpty {
                        GlassCard {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GWTheme.gold)
                                    .padding(.top, 1)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(carriedItems.count) item\(carriedItems.count == 1 ? "" : "s") carried forward")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(GWTheme.textPrimary)
                                    Text("These didn't get shaped yesterday. Review, edit, or remove them.")
                                        .font(.system(size: 11))
                                        .foregroundStyle(GWTheme.textMuted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Captured — \(dayDumpItems.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GWTheme.textGhost)
                                .padding(.bottom, 6)

                            ForEach(dayDumpItems) { item in
                                HStack(spacing: 10) {
                                    Circle().fill(GWTheme.gold.opacity(0.35)).frame(width: 6, height: 6)

                                    if item.carriedOver == true {
                                        Text("Carried")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color(hex: "1a1208"))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(GWTheme.gold.opacity(0.85))
                                            .clipShape(Capsule())
                                    }

                                    if editingItemId == item.id {
                                        TextField("Edit item", text: $editingText)
                                            .font(.system(size: 13))
                                            .foregroundStyle(GWTheme.textPrimary)
                                            .focused($isEditFocused)
                                            .submitLabel(.done)
                                            .onSubmit { commitEdit() }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    } else {
                                        Text(item.text)
                                            .font(.system(size: 13))
                                            .foregroundStyle(GWTheme.textMuted)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                guard !isViewingPastDay else { return }
                                                editingItemId = item.id
                                                editingText = item.text
                                                isEditFocused = true
                                            }
                                    }

                                    if editingItemId == item.id {
                                        Button("Save") { commitEdit() }
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(GWTheme.gold)
                                            .buttonStyle(.plain)
                                    } else {
                                        Button("×") { store.removeDumpItem(id: item.id) }
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(GWTheme.textGhost)
                                            .disabled(isViewingPastDay)
                                    }
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
                    if editingItemId != nil { commitEdit() }
                    isInputFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GWTheme.gold)
                .padding(.vertical, 6)
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
        guard !isViewingPastDay else {
            voiceStatusMessage = "Past days are read-only. Switch to today or a future day to capture items."
            return
        }

        let parsed = aiParseDumpItems(from: voice.transcript)
        guard !parsed.isEmpty else {
            voiceStatusMessage = voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Could not detect separate items. Try pausing between tasks."
            return
        }

        for item in parsed {
            store.addDumpItem(item, for: selectedDay)
        }

        voiceStatusMessage = "Added \(parsed.count) item\(parsed.count == 1 ? "" : "s") from voice capture."
        voice.clearTranscript()
    }

    private func commitEdit() {
        guard let id = editingItemId else { return }
        store.updateDumpItemText(id: id, text: editingText)
        editingItemId = nil
        editingText = ""
        isEditFocused = false
    }

    private func addTypedDumpItem() {
        guard !isViewingPastDay else { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isInputFocused = false
            return
        }
        store.addDumpItem(trimmed, for: selectedDay)
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
            Text("Get everything out of your head. List tasks at Work, Home, Hobby, School. Don't filter. Don't worry about the order.")
                .font(.system(size: 13))
                .foregroundStyle(GWTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
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
