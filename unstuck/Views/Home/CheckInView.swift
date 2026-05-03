import SwiftUI
import Combine
import AVFoundation
import Speech

// MARK: - Check-in View
// Entry point for each quest session. Voice or text input.
// Minimal UI — just the orb, the words, and a way to speak.

struct CheckInView: View {
    var userProfile: UserProfile
    var onQuestGenerated: (QuestResponse) -> Void
    var onDismiss: () -> Void

    @StateObject private var viewModel: CheckInViewModel

    init(userProfile: UserProfile, onQuestGenerated: @escaping (QuestResponse) -> Void, onDismiss: @escaping () -> Void) {
        self.userProfile = userProfile
        self.onQuestGenerated = onQuestGenerated
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: CheckInViewModel(energy: userProfile.energyLevel))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss button
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.appTextDim)
                            .padding(AppSpacing.md)
                    }
                    Spacer()
                }
                .padding(.top, AppSpacing.sm)

                Spacer()

                // Breathing orb — always visible, state reflects activity
                BreathingOrbView(
                    size: orbSize,
                    color: orbColor
                )
                .scaleEffect(viewModel.isListening ? 1.2 : 1.0)
                .animation(AppAnimation.spring, value: viewModel.isListening)

                Spacer().frame(height: AppSpacing.xxxl)

                // State-specific content
                Group {
                    switch viewModel.state {
                    case .idle:
                        idleContent
                    case .listening:
                        listeningContent
                    case .textInput:
                        textInputContent
                    case .processing:
                        processingContent
                    case .error(let msg):
                        errorContent(msg)
                    }
                }
                .animation(AppAnimation.fadeIn, value: viewModel.state.id)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .onChange(of: viewModel.generatedQuest) { _, quest in
            guard let quest else { return }
            Haptic.questArrived()
            onQuestGenerated(quest)
        }
    }

    // MARK: - Sub-views per state

    private var idleContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Text(AppCopy.CheckIn.voicePrompt)
                .font(.appQuote)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.startListening()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appAmber)
            }
            .buttonStyle(.plain)

            Button(AppCopy.CheckIn.switchToText) {
                viewModel.switchToTextInput()
            }
            .font(.appCaption)
            .foregroundStyle(Color.appTextDim)
        }
    }

    private var listeningContent: some View {
        VStack(spacing: AppSpacing.xl) {
            Text(viewModel.transcript.isEmpty ? AppCopy.CheckIn.voicePrompt : viewModel.transcript)
                .font(.appQuote)
                .foregroundStyle(viewModel.transcript.isEmpty ? Color.appTextDim : Color.appTextPrimary)
                .multilineTextAlignment(.center)
                .animation(AppAnimation.fadeIn, value: viewModel.transcript)

            Button {
                viewModel.stopListeningAndProcess()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.appAmber)
            }
            .buttonStyle(.plain)
        }
    }

    private var textInputContent: some View {
        VStack(spacing: AppSpacing.xl) {
            TextEditor(text: $viewModel.textInput)
                .font(.appBodyLarge)
                .foregroundStyle(Color.appTextPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 120)
                .accentColor(Color.appAmber)
                .overlay(
                    Group {
                        if viewModel.textInput.isEmpty {
                            Text(AppCopy.CheckIn.textPlaceholder)
                                .font(.appBodyLarge)
                                .foregroundStyle(Color.appTextDim)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(.vertical, 8)
                        }
                    }
                )

            HStack(spacing: AppSpacing.md) {
                Button(AppCopy.CheckIn.switchToVoice) {
                    viewModel.switchToVoice()
                }
                .font(.appCaption)
                .foregroundStyle(Color.appTextDim)

                Spacer()

                AppPrimaryButton(
                    title: "Find my quest",
                    isEnabled: !viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    viewModel.processTextInput()
                }
                .frame(width: 160)
            }
        }
    }

    private var processingContent: some View {
        Text(AppCopy.CheckIn.processingLabel)
            .font(.appBody)
            .foregroundStyle(Color.appTextSecondary)
            .multilineTextAlignment(.center)
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Text(message)
                .font(.appBody)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)

            Button(AppCopy.Shared.tryAgain) {
                viewModel.reset()
            }
            .font(.appLabel)
            .foregroundStyle(Color.appAmber)
        }
    }

    // MARK: - Computed helpers

    private var orbSize: CGFloat {
        switch viewModel.state {
        case .listening:   return 160
        case .processing:  return 140
        default:           return 110
        }
    }

    private var orbColor: Color {
        switch viewModel.state {
        case .processing: return Color.appAmber
        default:          return Color.appAmber.opacity(0.85)
        }
    }
}

// MARK: - CheckIn ViewModel

@MainActor
final class CheckInViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case listening
        case textInput
        case processing
        case error(String)

        var id: String {
            switch self {
            case .idle:        return "idle"
            case .listening:   return "listening"
            case .textInput:   return "textInput"
            case .processing:  return "processing"
            case .error:       return "error"
            }
        }
    }

    @Published var state: State = .idle
    @Published var transcript: String = ""
    @Published var textInput: String = ""
    @Published var isListening: Bool = false
    @Published var generatedQuest: QuestResponse?

    private let energy: EnergyLevel
    private let aiService = QuestAIService()
    private var speechRecognizer = SpeechRecognitionService()

    init(energy: EnergyLevel) {
        self.energy = energy
    }

    func startListening() {
        transcript = ""
        state = .listening
        isListening = true
        speechRecognizer.start { [weak self] text in
            self?.transcript = text
        }
    }

    func stopListeningAndProcess() {
        speechRecognizer.stop()
        isListening = false
        let input = transcript
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else {
            state = .idle
            return
        }
        Task { await generateQuest(from: input) }
    }

    func switchToTextInput() {
        speechRecognizer.stop()
        isListening = false
        state = .textInput
    }

    func switchToVoice() {
        state = .idle
    }

    func processTextInput() {
        let input = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        Task { await generateQuest(from: input) }
    }

    func reset() {
        state = .idle
        transcript = ""
        textInput = ""
    }

    private func generateQuest(from input: String) async {
        state = .processing
        do {
            let quest = try await aiService.generateQuest(userInput: input, energy: energy)
            generatedQuest = quest
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Speech Recognition Wrapper

final class SpeechRecognitionService: NSObject {
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: .current)

    func start(onUpdate: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            DispatchQueue.main.async { self.beginRecognition(onUpdate: onUpdate) }
        }
    }

    private func beginRecognition(onUpdate: @escaping (String) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { result, _ in
            if let result {
                DispatchQueue.main.async { onUpdate(result.bestTranscription.formattedString) }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
}
