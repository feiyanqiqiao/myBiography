//
//  SpeechRecognazier.swift
//  myBiography
//
//  Created by zhangqiao on 2025/7/17.
//

import SwiftUI
import Speech

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
    /// Holds the text returned when the last final result was received
    private var lastFinalTranscript: String = ""
    /// Text with punctuation appended for completed utterances
    private var completedText: String = ""

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
        guard let result = result else {
            if error != nil {
                self.stopRecording()
            }
            return
        }

        let transcription = result.bestTranscription.formattedString
        if result.isFinal {
            var newSegment = transcription
            if newSegment.hasPrefix(lastFinalTranscript) {
                newSegment.removeFirst(lastFinalTranscript.count)
            }
            newSegment = newSegment.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newSegment.isEmpty {
                completedText += newSegment + punctuationForCurrentLocale()
            }
            lastFinalTranscript = transcription
            DispatchQueue.main.async {
                self.recognizedText = self.completedText
            }
        } else {
            var partial = transcription
            if partial.hasPrefix(lastFinalTranscript) {
                partial.removeFirst(lastFinalTranscript.count)
            }
            DispatchQueue.main.async {
                self.recognizedText = self.completedText + partial
            }
        }

        if error != nil {
            self.stopRecording()
        }
    }

    private func punctuationForCurrentLocale() -> String {
        let lang = currentLocale.language.languageCode?.identifier ?? "en"
        switch lang {
        case "zh", "ja":
            return "。"
        default:
            return ". "
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
    }
}
