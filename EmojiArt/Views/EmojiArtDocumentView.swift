//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//  Adapted to assignment 4 requirements by Ulrich Braß

import SwiftUI

struct EmojiArtDocumentView: View {
    @EnvironmentObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            // Scrollable list of Emojis, that can be picked from
            ScrollView(.horizontal) {
                HStack {
                    // map turns string into array of strings
                    // make strings identifiable by using the id option with key path self
                    ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: self.defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                    }
                } //HStack
            } // Scroll View
                // let some space on left and right
            .padding(.horizontal)
            // how much space have we left for the drawing area
            GeometryReader { geometry in
                ZStack {
                    // Background Image
                    Color.white.overlay(
                        OptionalImageView(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZoomOrDeSelectEmojis(in: geometry.size))
                        .gesture(self.panGesture())
                   // Emojis, that have been dropped into the document
                    ForEach(self.document.emojis) { emoji in
                        // present view based on presence of emoji in the selection set 
                        EmojiSelectionView ( emoji : emoji, zoomScale: self.zoomScale, size : geometry.size)
                            .font(animatableWithSize: emoji.fontSize * self.zoomScale)
                            .position(self.position(for: emoji, in: geometry.size))
                            // mark/unmark emoji by putting it into the selection set
                            
                    } //ForEach
                } //ZStack
                // drawing keep inside bounds of the view
                .clipped()
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                // 'of:' lists the supportedTypes as array of URIs, the uniform type identifiers that describe the types of content
                // this view can accept through drag and drop (image and Emoji(String) here).
                // 'isTargeted:' is a binding that updates when a drag and drop operation enters or exits the drop target area.
                // The binding’s value is true when the cursor is inside the area, and false when the cursor is outside, but
                // we ignore this here, because we are only interested in the completion
                // 'action: is a closure that takes the dropped content and responds appropriately.
                // - The first parameter to action (providers) contains the dropped items, with types specified by supportedTypes.
                // - The second parameter (location) contains the drop location in this view’s coordinate space
                // -> Return true if the drop operation was successful; otherwise, return false.
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                    // SwiftUI bug (as of 13.4)? the location is supposed to be in our coordinate system
                    // however, the y coordinate appears to be in the global coordinate system
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location) // returns if drop succeded
                }
            } //Geometry reader
        } //VStack
    } // body
    
    // Gesture handling:
    
    
    // Pinching gesture handling
    @State private var steadyStateZoomScale: CGFloat = 1.0
    // the following state is only used while the gesture is going on
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        self.steadyStateZoomScale * (self.hasSelection ? 1 : gestureZoomScale)
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            // $ turns gestureZoomScale into a binding, so value can change
            // gestureZoomScale is an inout parameter
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                if self.hasSelection {
                    self.scaleAllSelectedEmojis(by : 1 + latestGestureScale - gestureZoomScale)
                }
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                if !self.hasSelection {
                    self.steadyStateZoomScale *= finalGestureScale
                }
            }
    }
    
    private func scaleAllSelectedEmojis(by scale : CGFloat){
        self.document.selection.forEach{ selectedEmoji in
            self.document.scaleEmoji(selectedEmoji, by : scale)
        }
    }
    
    private func isSelected(emoji: EmojiArtModel.Emoji) -> Bool {
        self.document.selection.contains(matching : emoji)
    }
    
    private var hasSelection: Bool {
        !self.document.selection.isEmpty
    }
    // Pinching
    
     // Drag gesture handling
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
   
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            self.steadyStatePanOffset = self.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
        }
    }
    // End Drag

    // Background click gestures:
    private func doubleTapToZoomOrDeSelectEmojis(in size: CGSize) -> some Gesture {
        // Bring background image to the right size - by double click
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
            }
        // With lower priority, to make sure double taps don’t get missed because SwiftUI recognizes the single tap part of a
        // double tap and doesn’t give an opportunity for the second tap to be recognized as part of a double tap gesture.
        .exclusively (before:
        // Single-tapping on the background of EmojiArt (i.e. single-tapping anywhere except on an Emoji
        // will deselect all emoji.
            TapGesture(count: 1)
            .onEnded {
                self.document.selection.removeAll()
            }
        )
    }

    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            // recenter
            self.steadyStatePanOffset = .zero
            self.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
   //
    
    private func position(for emoji: EmojiArtModel.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            // print("dropped \(url)")
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
} // View
