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
    /// Last formatted transcript we processed
    private var lastFormatted: String = ""

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
        lastFormatted = ""
        
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
                let formatted = result.bestTranscription.formattedString
                var update = formatted
                if formatted.hasPrefix(self.lastFormatted) {
                    update = String(formatted.dropFirst(self.lastFormatted.count))
                } else {
                    self.recognizedText = formatted
                    self.lastFormatted = formatted
                    if result.isFinal {
                        self.recognizedText += "\n"
                    }
                    return
                }

                if self.recognizedText.hasSuffix("\n") && update.hasPrefix(" ") {
                    update.removeFirst()
                }

                self.recognizedText += update
                self.lastFormatted = formatted

                if result.isFinal {
                    self.recognizedText += "\n"
                }
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

        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil

        // Leave any partial text as-is in recognizedText

    }
}
