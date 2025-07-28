//
//  ContentView1.swift
//  myBiography
//
//  Created by zhangqiao on 2025/7/17.
//
import SwiftUI
import Speech

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false

    private func languageName(for locale: Locale) -> String {
        switch locale.identifier {
        case "en-US":
            return "en-US"
        case "zh-CN":
            return "中文"
        case "ja-JP":
            return "日本語"
        default:
            return locale.identifier
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Picker(Localization.text(for: "language", locale: speechRecognizer.currentLocale), selection: $speechRecognizer.currentLocale) {
                ForEach(speechRecognizer.supportedLocales, id: \.self) { locale in
                    Text(languageName(for: locale)).tag(locale)
                }
            }
            .pickerStyle(.segmented)

            Text(speechRecognizer.recognizedText)
                .padding()
                .frame(maxHeight: 200)
                .border(Color.gray)

            Button(action: toggleRecording) {
                Text(isRecording ? Localization.text(for: "stop_recording", locale: speechRecognizer.currentLocale) : Localization.text(for: "start_recording", locale: speechRecognizer.currentLocale))
                    .padding()
                    .foregroundColor(.white)
                    .background(isRecording ? Color.red : Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
            isRecording = false
        } else {
            do {
                try speechRecognizer.startRecording()
                isRecording = true
            } catch {
                speechRecognizer.recognizedText = Localization.text(for: "recording_unavailable", locale: speechRecognizer.currentLocale)
            }
        }
    }
}
