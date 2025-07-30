//
//  TextProcessor.swift
//  myBiography
//
//  Created by Codex.
//

import Foundation
import NaturalLanguage

/// Utility for tokenizing text and inserting basic punctuation for English,
/// Chinese, and Japanese.
struct TextProcessor {
    /// Returns an array of sentences for the given text using `NLTokenizer`.
    static func sentences(in text: String, language: NLLanguage) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        tokenizer.setLanguage(language)
        var result: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            result.append(String(text[range]))
            return true
        }
        return result
    }

    /// Returns an array of word tokens for the given text using `NLTokenizer`.
    static func words(in text: String, language: NLLanguage) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(language)
        var result: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            result.append(String(text[range]))
            return true
        }
        return result
    }

    /// Inserts punctuation marks by inferring whether each sentence is a question
    /// or a statement. The function is intentionally simple and relies on
    /// heuristics tailored for English, Chinese and Japanese.
    static func punctuate(_ text: String, language: NLLanguage) -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentences = self.sentences(in: clean, language: language)
        var punctuated: [String] = []
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if isQuestion(trimmed, language: language) {
                punctuated.append(trimmed + "?")
            } else {
                punctuated.append(trimmed + ".")
            }
        }
        return punctuated.joined(separator: " ")
    }

    /// Rudimentary question detection heuristics for the supported languages.
    private static func isQuestion(_ sentence: String, language: NLLanguage) -> Bool {
        let lowered = sentence.lowercased()
        switch language {
        case .english:
            let prefixes = ["who", "what", "when", "where", "why", "how", "is", "are", "do", "did", "does", "can", "could", "should", "would", "will"]
            for prefix in prefixes {
                if lowered.hasPrefix(prefix + " ") { return true }
            }
            return false
        case .simplifiedChinese, .traditionalChinese:
            return sentence.contains("吗") || sentence.hasSuffix("吗") || sentence.contains("呢") || sentence.hasSuffix("呢")
        case .japanese:
            return sentence.contains("か") || sentence.hasSuffix("か")
        default:
            return false
        }
    }
}
