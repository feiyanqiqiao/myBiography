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
                    self.recognizedText = "Speech recognition authorization denied."
                @unknown default:
                    self.recognizedText = "Speech recognition not available."
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
            self.recognizedText = "(Listening...)"
        }
    }

    private func handleResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            DispatchQueue.main.async {
                self.recognizedText = result.bestTranscription.formattedString
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
    }
}
