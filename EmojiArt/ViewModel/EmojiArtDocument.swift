//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

class EmojiArtDocument: ObservableObject
{
    static let palette: String = "⭐️⛈🍎🌏🥨⚾️"
    
    // workaround for property observer problem with property wrappers
    // @Published removed here, because we want to use didSet, which did not work at the time of writing the code
    private var emojiArt: EmojiArtModel {
        willSet {
            // keep the published semantics (however not completely identical)
            objectWillChange.send()
        }
        didSet {
            // make this state persistent 
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    // here is our key for persistent storage in user defaults
    private static let untitled = "EmojiArtDocument.Untitled"
    
    // this initializer will bring back everything from last session
    init() {
        // get emojis
        emojiArt = EmojiArtModel(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArtModel()
        // get background
        fetchBackgroundImageData()
    }
        
    @Published private(set) var backgroundImage: UIImage?
    // mark an emoji for further actions
    // Selection is not part of the model. It is purely a way of letting the user express which emoji they want to resize or move.
    @Published var selection  = Set<EmojiArtModel.Emoji>()
    
    // the emojis in my document
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    
    
    
    // MARK: - Intent(s)
    // needed, because emojiArt is private
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func deleteEmoji(_ emoji: EmojiArtModel.Emoji) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.deleteEmoji(index)
        }
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }

    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    // fetch in the background
    private func fetchBackgroundImageData() {
        // clear background
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            // a non-UI queue with a certain quality of service, defined as:
            // the user just asked to do this, so do it now
            DispatchQueue.global(qos: .userInitiated).async {
                // Plopping this closure onto a Queue
                // .async will execute this closure, whenever that closure gets to the front of the queue
                // try and return nil, if it fails
                if let imageData = try? Data(contentsOf: url) {
                    // The following needs to go the main queue, because the assignment to backgroundImage cause UI activity
                    DispatchQueue.main.async {
                        // make sure, that this image is still the one requested, otherwise ignore
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }// main queue
                }
            } // globa queue
        }
    } // fetchBackgroundImageData
} //class

extension EmojiArtModel.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}

extension Set where Element : Identifiable {
    // adding a toggleMatching function via an extension (that adds/removes an element to/from the Set based on
    // whether it’s already there based on Identifiable)
    mutating func toggleMatching(toggle element: Element){
        if let index = firstIndex(matching : element) {
            self.remove(at : index)
        } else {
            self.update(with : element)
        }
    }
}
