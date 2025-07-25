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
    private var bestResult: (text: String, confidence: Float) = ("", 0)

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
            let confidence = averageConfidence(result.bestTranscription)
            if confidence > bestResult.confidence {
                bestResult = (result.bestTranscription.formattedString, confidence)
                DispatchQueue.main.async {
                    self.recognizedText = self.bestResult.text
                }
            }
        }
        if error != nil || (result?.isFinal ?? false) {
            self.stopRecording()
        }
    }

    private func averageConfidence(_ transcription: SFTranscription) -> Float {
        guard !transcription.segments.isEmpty else { return 0 }
        let total = transcription.segments.reduce(0) { $0 + $1.confidence }
        return total / Float(transcription.segments.count)
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
        bestResult = ("", 0)
    }
}
