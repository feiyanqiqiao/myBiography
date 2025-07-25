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
    private let audioEngine = AVAudioEngine()
    private var requests: [SFSpeechAudioBufferRecognitionRequest] = []
    private var tasks: [SFSpeechRecognitionTask] = []
    private var recognizers: [SFSpeechRecognizer] = []
    private let supportedLocales: [Locale] = [
        Locale(identifier: "en-US"),
        Locale(identifier: "zh-CN"),
        Locale(identifier: "ja-JP")
    ]
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
        recognizers = supportedLocales.compactMap { SFSpeechRecognizer(locale: $0) }
        guard !recognizers.isEmpty, recognizers.allSatisfy({ $0.isAvailable }) else {
            throw SpeechRecognizerError.authorizationDenied
        }

        requests = recognizers.map { _ in SFSpeechAudioBufferRecognitionRequest() }
        requests.forEach { $0.shouldReportPartialResults = true }
        let inputNode = audioEngine.inputNode

        tasks = zip(recognizers, requests).map { recognizer, request in
            recognizer.recognitionTask(with: request) { result, error in
                self.handleResult(result: result, error: error)
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            for request in self.requests {
                request.append(buffer)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
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
        for request in requests { request.endAudio() }
        for task in tasks { task.cancel() }
        requests.removeAll()
        tasks.removeAll()
        recognizers.removeAll()
        bestResult = ("", 0)
    }
}
