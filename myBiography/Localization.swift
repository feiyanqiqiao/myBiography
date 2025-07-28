import Foundation

struct Localization {
    static let translations: [String: [String: String]] = [
        "en": [
            "language": "Language",
            "start_recording": "Start Recording",
            "stop_recording": "Stop Recording",
            "recording_unavailable": "Recording unavailable.",
            "speech_authorization_denied": "Speech recognition authorization denied.",
            "speech_not_available": "Speech recognition not available.",
            "listening": "(Listening...)"
        ],
        "zh": [
            "language": "语言",
            "start_recording": "开始录音",
            "stop_recording": "结束录音",
            "recording_unavailable": "无法录音。",
            "speech_authorization_denied": "语音识别权限被拒绝。",
            "speech_not_available": "语音识别无法使用。",
            "listening": "（正在听...）"
        ],
        "ja": [
            "language": "言語",
            "start_recording": "録音開始",
            "stop_recording": "録音停止",
            "recording_unavailable": "録音できません。",
            "speech_authorization_denied": "音声認識の許可が拒否されました。",
            "speech_not_available": "音声認識は利用できません。",
            "listening": "（聞いています...）"
        ]
    ]

    static func text(for key: String, locale: Locale) -> String {
        let lang = locale.languageCode ?? "en"
        if let value = translations[lang]?[key] {
            return value
        }
        return translations["en"]?[key] ?? key
    }
}
