// OpenGlass - TranslatorMode.swift

import Foundation

/// Real-time Mandarin ↔ English translation mode.
/// TODO: Translate spoken audio between Mandarin and English
/// TODO: Translate visible text (signs, menus, etc.)
/// TODO: Configure source/target language pair
/// TODO: Future: support additional language pairs
struct TranslatorMode: OpenGlassMode {
    let id = "translator"
    let displayName = "Translator"
    let systemInstruction = "You are a real-time translator. Translate everything between Mandarin Chinese and English. When you hear speech in one language, respond with the translation in the other. When you see text, translate it."
    let enabledTools: [String] = []

    func activate() { /* TODO */ }
    func deactivate() { /* TODO */ }
}
