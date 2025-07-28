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
            "language": "\u8bed\u8a00",
            "start_recording": "\u5f00\u59cb\u5f55\u97f3",
            "stop_recording": "\u7ed3\u675f\u5f55\u97f3",
            "recording_unavailable": "\u65e0\u6cd5\u5f55\u97f3\u3002",
            "speech_authorization_denied": "\u8bed\u97f3\u8bc6\u522b\u6743\u9650\u88ab\u62d2\u7edd\u3002",
            "speech_not_available": "\u8bed\u97f3\u8bc6\u522b\u65e0\u6cd5\u4f7f\u7528\u3002",
            "listening": "\uff08\u6b63\u5728\u542c...\uff09"
        ],
        "ja": [
            "language": "\u8a00\u8a9e",
            "start_recording": "\u9332\u97f3\u958b\u59cb",
            "stop_recording": "\u9332\u97f3\u505c\u6b62",
            "recording_unavailable": "\u9332\u97f3\u3067\u304d\u307e\u305b\u3093\u3002",
            "speech_authorization_denied": "\u97f3\u58f0\u8a8d\u8b58\u306e\u8a31\u53ef\u304c\u62d2\u5426\u3055\u308c\u307e\u3057\u305f\u3002",
            "speech_not_available": "\u97f3\u58f0\u8a8d\u8b58\u306f\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002",
            "listening": "\uff08\u805e\u3044\u3066\u3044\u307e\u3059...\uff09"
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
