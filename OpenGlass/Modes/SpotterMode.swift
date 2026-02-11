import UIKit

/// Spotter mode — object identification with "What's that?" and web search.
struct SpotterMode: GlassMode {
    let id = "spotter"
    let name = "Spotter"
    let icon = "eye"

    let systemInstruction = """
        You are an object identification assistant for someone wearing smart glasses.

        When the user asks "What's that?", "What am I looking at?", or similar questions:
        1. Look at the camera feed and identify what you see.
        2. Give a brief, confident identification.
        3. If the user wants more details, use the execute tool to search the web for information.

        Be concise — start with the identification, then offer to look up more details.
        Focus on practical information: what it is, what it's used for, price range if relevant.

        For plants, animals, landmarks, products, art, etc. — identify first, then offer deeper info via search.
        """

    var toolDeclarations: [[String: Any]] {
        [ToolDeclarations.execute]
    }

    let activationPhrases: [String] = [
        "switch to spotter",
        "spotter mode",
        "what's that",
        "what is that",
        "what am i looking at",
        "identify this",
        "what's this"
    ]
}
