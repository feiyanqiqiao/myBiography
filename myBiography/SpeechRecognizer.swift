//
//  SpeechRecognazier.swift
//  myBiography
//
//  Created by zhangqiao on 2025/7/17.
//

import SwiftUI
import Speech
import NaturalLanguage

// ViewModel handling speech recognition
enum SpeechRecognizerError: Error {
    case authorizationDenied
    case authorizationRestricted
    case audioEngineError
}

class SpeechRecognizer: ObservableObject {
    @Published var recognizedText: String = ""
    /// Locale selected for recognition
    @Published var currentLocale: Locale = Locale(identifier: "en-US")

    /// Locales presented to the user
    let supportedLocales: [Locale] = [
        Locale(identifier: "en-US"),
        Locale(identifier: "zh-CN"),
        Locale(identifier: "ja-JP")
    ]

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    /// Last raw transcript received from the recognizer
    private var lastTranscript: String = ""
    /// Index of the last processed segment
    private var lastSegmentIndex: Int = 0
    /// Finalized text with punctuation
    private var finalizedText: String = ""
    /// Current sentence being recognized
    private var currentSentence: String = ""

    init() {
        requestAuthorization()
    }

    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    break
                case .denied, .restricted, .notDetermined:
                    self.recognizedText = Localization.text(for: "speech_authorization_denied", locale: self.currentLocale)
                @unknown default:
                    self.recognizedText = Localization.text(for: "speech_not_available", locale: self.currentLocale)
                }
            }
        }
    }

    func startRecording() throws {
        guard let recognizer = SFSpeechRecognizer(locale: currentLocale), recognizer.isAvailable else {
            throw SpeechRecognizerError.authorizationDenied
        }

        speechRecognizer = recognizer
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        // Reset transcript state at the start of a new recording session
        lastTranscript = ""
        lastSegmentIndex = 0
        finalizedText = ""
        currentSentence = ""

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            self?.handleResult(result: result, error: error)
        }

        DispatchQueue.main.async {
            self.recognizedText = Localization.text(for: "listening", locale: self.currentLocale)
        }
    }

    private func handleResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            DispatchQueue.main.async {
                let segments = result.bestTranscription.segments
                if segments.count > self.lastSegmentIndex {
                    for i in self.lastSegmentIndex..<segments.count {
                        let seg = segments[i]
                        self.currentSentence += seg.substring
                        if i < segments.count - 1 {
                            self.currentSentence += " "
                        }
                    }
                    self.lastSegmentIndex = segments.count
                }

                if result.isFinal {
                    let langCode = self.currentLocale.language.languageCode?.identifier ?? "en"
                    let language = NLLanguage(rawValue: langCode)
                    let punctuated = TextProcessor.punctuate(self.currentSentence, language: language)
                    self.finalizedText += punctuated + "\n"
                    self.currentSentence = ""
                    self.lastSegmentIndex = 0
                }

                self.recognizedText = self.finalizedText + self.currentSentence
                self.lastTranscript = result.bestTranscription.formattedString
            }
        }
        if error != nil {
            self.stopRecording()
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        if !currentSentence.isEmpty {
            let langCode = currentLocale.language.languageCode?.identifier ?? "en"
            let language = NLLanguage(rawValue: langCode)
            let punctuated = TextProcessor.punctuate(currentSentence, language: language)
            finalizedText += punctuated + "\n"
            currentSentence = ""
        }
        recognizedText = finalizedText

        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
    }
}
