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

    var body: some View {
        VStack(spacing: 20) {
            Picker("Language", selection: $speechRecognizer.currentLocale) {
                ForEach(speechRecognizer.supportedLocales, id: \.self) { locale in
                    Text(locale.identifier).tag(locale)
                }
            }
            .pickerStyle(.segmented)

            Text(speechRecognizer.recognizedText)
                .padding()
                .frame(maxHeight: 200)
                .border(Color.gray)

            Button(action: toggleRecording) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
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
                speechRecognizer.recognizedText = "Recording unavailable."
            }
        }
    }
}
