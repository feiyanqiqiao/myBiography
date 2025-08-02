//
//  SpeechRecognizer.swift
//  myBiography
//
//  Created by zhangqiao on 2025/7/17.
//

import SwiftUI
import Speech

enum SpeechRecognizerError: Error {
    case authorizationDenied
    case authorizationRestricted
    case audioEngineError
}

class SpeechRecognizer: ObservableObject {
    // MARK: - 对外属性
    @Published var displayText: String = ""
    @Published var currentLocale: Locale = Locale(identifier: "en-US")
    let supportedLocales: [Locale] = [
        Locale(identifier: "en-US"),
        Locale(identifier: "zh-CN"),
        Locale(identifier: "ja-JP")
    ]
    
    // MARK: - 内部状态
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    
    /// 辅助去重，避免同一内容重复拼接
    private var lastFinalTranscript: String = ""
    
    /// 只保存已经“断句+加标点”的所有确认文本，不含当前partial。
    /// 用于累积最终结果，最终保存、输出用
    private var completedText: String = ""
    
    /// 保存当前最新的partial识别片段（未断句、未加标点的内容）。
    /// 每次语音识别有新结果时更新，
    /// 用于在2秒无新输入时，作为自动断句拼接的内容。
    private var lastPartial: String = ""
    
    /// 用于检测“文本无变化”时自动断句的定时器。
    /// 每次检测到新文本输入时重置，
    /// 如果X秒内没有新文本输入，则定时器触发，将当前partial拼接为完整文本并加标点。
    private var noInputTimer: Timer?
    
    /// 记录最近一次partial内容更新的时间点。
    /// 可用于后续统计用户实际说话间隔（本方案可选，主要依赖于 noInputTimer 控制自动断句）。
    private var lastPartialTimestamp: Date = Date()
    
    // MARK: - 初始化
    init() {
        requestAuthorization()
    }
    
    // MARK: - 权限请求
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    break
                case .denied, .restricted, .notDetermined:
                    self.displayText = Localization.text(for: "speech_authorization_denied", locale: self.currentLocale)
                @unknown default:
                    self.displayText = Localization.text(for: "speech_not_available", locale: self.currentLocale)
                }
            }
        }
    }

    // MARK: - 录音与识别主流程
    func startRecording() throws {
        // --- 新增：重置历史内容 ---
        DispatchQueue.main.async {
            self.displayText = ""
        }
        completedText = ""
        lastFinalTranscript = ""
        lastPartial = ""
        noInputTimer?.invalidate()
        
        guard let recognizer = SFSpeechRecognizer(locale: currentLocale), recognizer.isAvailable else {
            throw SpeechRecognizerError.authorizationDenied
        }
        speechRecognizer = recognizer
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            self?.handleResult(result: result, error: error)
        }

        DispatchQueue.main.async {
            self.displayText = Localization.text(for: "listening", locale: self.currentLocale)
        }
    }
    
    // MARK: - 语音识别结果处理
    private func handleResult(result: SFSpeechRecognitionResult?, error: Error?) {
        guard let result = result else {
            if error != nil {
                self.stopRecording()
            }
            return
        }

        let transcription = result.bestTranscription.formattedString

        if result.isFinal {
            // Final 结果，拼接并加标点
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
                self.displayText = self.completedText
            }
            lastPartial = ""
            noInputTimer?.invalidate()
        } else {
            // 实时结果，基于新内容自动断句
            var partial = transcription
            if partial.hasPrefix(lastFinalTranscript) {
                partial.removeFirst(lastFinalTranscript.count)
            }
            let partialTrimmed = partial.trimmingCharacters(in: .whitespacesAndNewlines)
            // 如果 partial 有变化，重置 timer
            if partialTrimmed != lastPartial {
                lastPartial = partialTrimmed
                lastPartialTimestamp = Date()
                resetNoInputTimer()
            }
            DispatchQueue.main.async {
                self.displayText = self.completedText + partial
            }
        }

        if error != nil {
            self.stopRecording()
        }
    }
    
    // MARK: - 基于文本无变化的自动断句
    private func resetNoInputTimer() {
        noInputTimer?.invalidate()
        noInputTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.handleNoInputSentenceBreak()
        }
    }
    
    private func handleNoInputSentenceBreak() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let partial = self.lastPartial.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !partial.isEmpty else { return }
            self.completedText += partial + self.punctuationForCurrentLocale()
            self.lastFinalTranscript += partial
            self.displayText = self.completedText
            self.lastPartial = ""
        }
    }
    
    // MARK: - 标点符号多语言支持
    private func punctuationForCurrentLocale() -> String {
        let lang = currentLocale.language.languageCode?.identifier ?? "en"
        switch lang {
        case "zh", "ja":
            return "。"
        default:
            return ". "
        }
    }
    
    // MARK: - 结束录音，确保补全最后一句
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
        noInputTimer?.invalidate()
        
        // 补最后 partial
        let lastLeft = lastPartial.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastLeft.isEmpty {
            completedText += lastLeft + punctuationForCurrentLocale()
            displayText = completedText
            lastPartial = ""
        }
    }
}

