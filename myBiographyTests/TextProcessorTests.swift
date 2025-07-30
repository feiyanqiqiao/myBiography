import NaturalLanguage
import Testing
@testable import myBiography

struct TextProcessorTests {
    @Test func englishQuestion() {
        let input = "how are you i am fine"
        let result = TextProcessor.punctuate(input, language: .english)
        #expect(result == "how are you? i am fine.")
    }

    @Test func chineseSentence() {
        let input = "你好吗 我很好"
        let result = TextProcessor.punctuate(input, language: .simplifiedChinese)
        #expect(result == "你好吗? 我很好.")
    }
}
