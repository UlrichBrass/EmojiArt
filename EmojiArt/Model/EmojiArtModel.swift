//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import Foundation
// Renamed struct name, because it matched the project name, which breaks all previews, because of
// naming conflict
struct EmojiArtModel: Codable {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    // Coordinate system will have (0, 0) in the middle of the window
    struct Emoji: Identifiable, Codable, Hashable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        let id: Int
        
        // need to be identifiable only in the context of this file
        // nobody can create an Emoji with calling this init, only within the contect of this file ( see addEmoji)
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    } // Emoji
    
    // encode EmojiArt to JSON (prerequisite: needs to be Codable)
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    //create by reading from JSON, failable initializer
    init?(json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArtModel.self, from: json!) {
            // replace self from JSON input
            self = newEmojiArt
        } else {
            return nil
        }
    }
    
    init() { }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
    
    mutating func deleteEmoji(_ index: Int) {
        emojis.remove(at : index)
    }
} // EmojiArtModel
