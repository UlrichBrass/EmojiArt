//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject
{
    
    // workaround for property observer problem with property wrappers
    @Published private var emojiArt: EmojiArtModel
    
    // here is our key for persistent storage in user defaults
    private static let untitled = "EmojiArtDocument.Untitled"
    
    // cancels subscription if View Model disappears
    private var autosaveCancellable : AnyCancellable?
    
    // this initializer will bring back everything from last session
    init() {
        // get emojis
        emojiArt = EmojiArtModel(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArtModel()
        // use the projected value of the published var emojiArt, which is a publisher
        // sink is a subscriber with closure-based behavior.
        autosaveCancellable = $emojiArt.sink{ emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey : EmojiArtDocument.untitled)
            print(String(data: emojiArt.json!, encoding: .utf8)!)
        }
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
    
    var backgroundURL : URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }
    // cancels subscription if View Model disappears
    private var fetchImageCancellable : AnyCancellable?
    
    // fetch in the background
    private func fetchBackgroundImageData() {
        // clear background
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            // make sure, that no other image load is in progress
            fetchImageCancellable?.cancel()
            // use URL session with a shared singleton session object that gives you a reasonable default behavior for creating tasks.
            // Use the shared session to fetch the contents of a URL to memory with just a few lines of code.
            let session = URLSession.shared
            // Get a publisher that wraps a URL session data task for a given URL on global queue
            // The publisher publishes data when the task completes, or terminates if the task fails with an error.
            let publisher = session.dataTaskPublisher(for: url)
                // Transforms all elements from the upstream publisher with a provided closure, to receive the image
                .map {data, URLResponse in
                    UIImage(data : data)
                }
                // this needs to go the main queue, because the assignment to backgroundImage cause UI activity
                .receive(on : DispatchQueue.main)
                // handle errors as nil values
                .replaceError(with : nil)
            // A cancellable instance; used for the end assignment of the received value. Deallocation of the result will tear down the subscription stream.
            fetchImageCancellable = publisher.assign(to: \.backgroundImage, on: self)
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
