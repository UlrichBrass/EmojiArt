//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import Combine


class EmojiArtDocument: ObservableObject, Hashable, Identifiable
{
    //EmojiArtDocument needs to conform to hashable, if we want to manage it in document store
    // Therefore we add an id and hash and compare functions, and initialize the id in the init function
    let id : UUID
    
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    // workaround for property observer problem with property wrappers
    @Published private var emojiArt: EmojiArtModel
    //Keep track of background presentation, by keeping the steady states in view model
    @Published var steadyStateZoomScale: CGFloat = 1.0
    @Published var steadyStatePanOffset: CGSize = .zero
    //
    
    // cancels subscription if View Model disappears
    private var autosaveCancellable : AnyCancellable?
    
    // this initializer will bring back everything from last session from user defaults
    // keep init comaptible if existing code, parameter is optionall and even can be nil
    init(id : UUID? = nil) {
        self.id = id ?? UUID()
        // here is our key for persistent storage in user defaults
        let defaultsKey = "EmojiArtDocument.\(self.id.uuidString)"
        
        // get emojis
        emojiArt = EmojiArtModel(json: UserDefaults.standard.data(forKey: defaultsKey)) ?? EmojiArtModel()
        // use the projected value of the published var emojiArt, which is a publisher
        // sink is a subscriber with closure-based behavior.
        autosaveCancellable = $emojiArt.sink{ emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey : defaultsKey)
            print(String(data: emojiArt.json!, encoding: .utf8)!)
        }
        // get background
        fetchBackgroundImageData()
    }
    
    // As an alternative way to retrieve and store settings in the file system, instead of user defaults
    // The user defaults implementation will be kept, and another init for file system will be provided
    
    init(url : URL){
        self.id = UUID()
        self.url = url
        // create EmojiArModel by using its failable initializer by passing json data read from url, or a blank one if url (not yet) exists
        self.emojiArt = EmojiArtModel(json: try? Data(contentsOf: url)) ??  EmojiArtModel()
        
        // get background
        fetchBackgroundImageData()
        // do autosave
        autosaveCancellable = $emojiArt.sink{ emojiArt in
            self.save(emojiArt)
        }
    }
    // In addition to autosave, do an immediate save, whenever  url changes
    var url : URL? { didSet {
            self.save(self.emojiArt)
        }
    }
    // save to file system
    private func save(_ emojiArt : EmojiArtModel){
        if url != nil {
            try? emojiArt.json?.write(to: url!)
        }
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
