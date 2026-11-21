import Foundation
import SwiftData

@Model
final class Game {
    var title: String
    var fileName: String
    var gameID: String?
    var bookmark: Data
    var isFavorite: Bool
    var lastPlayed: Date?
    var addedAt: Date
    var resolutionScale: Int
    var frameskip: Int

    init(title: String, fileName: String, gameID: String?, bookmark: Data) {
        self.title = title
        self.fileName = fileName
        self.gameID = gameID
        self.bookmark = bookmark
        self.isFavorite = false
        self.lastPlayed = nil
        self.addedAt = Date()
        self.resolutionScale = 1
        self.frameskip = 0
    }
}
