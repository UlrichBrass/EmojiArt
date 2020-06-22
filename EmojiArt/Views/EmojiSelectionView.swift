//
//  EmojiSelectionView.swift
//  EmojiArt
//
//  Created by Ulrich Braß on 16.06.20.
//
//

import SwiftUI

// Show an Emoji selected/deselected based on binding selection
struct EmojiSelectionView: View {
    @EnvironmentObject var document: EmojiArtDocument
    var emoji : EmojiArtModel.Emoji
    var zoomScale: CGFloat
    var documentSize : CGSize
    var body: some View {
        Text(emoji.text)
            .gesture(self.panGesture())
            // look into the selection set to find out which emoji to mark as selected
            .onTapGesture {
                // Tapping on an unselected emoji selects it.
                // Tapping on a selected emoji unselects it
                self.document.selection.toggleMatching(toggle : self.emoji)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(style: StrokeStyle(lineWidth:  self.document.selection.contains (matching : emoji) ? 4 : 0, dash: [15.0]))
            )
    } // body
    
    // Emoji Drag gesture handling
     @GestureState private var gesturePanOffset: CGSize = .zero
    
     private func panGesture() -> some Gesture {
         DragGesture()
         .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
            //print("latest: \(latestDragGestureValue.translation) gestureOffset: \(gesturePanOffset)")
            self.moveAllSelectedEmojis(by :  ((latestDragGestureValue.translation ) / self.zoomScale ))
         }
           
     }
     // End Drag 
    
    // move selected Emojis and remove emoji if moved beyond the border of the document
    private func moveAllSelectedEmojis(by offset : CGSize){
        // all emojis that are selected
        self.document.selection.forEach{ selectedEmoji in
            // move to new position
            self.document.moveEmoji(selectedEmoji, by : offset)
            
            if let index = document.emojis.firstIndex(matching: selectedEmoji){
                if emojiIsOutsideDocumentArea(index : index)  {
                    // remove from model
                    document.deleteEmoji(selectedEmoji)
                    // remove from selection
                    document.selection.toggleMatching(toggle: selectedEmoji)
                    //print("emoji deleted \(index) id: \(selectedEmoji.id)")
                    
                }
            }
        }
    }
    // Check if emoji has been moved outside of the document background
    private func emojiIsOutsideDocumentArea(index : Int) -> Bool {
        let maxWidth = Int(documentSize.width  / 2)
        let maxHeight = Int(documentSize.height  / 2)
        let margin = 6
        //print ("x= \(abs(document.emojis[index].x) ) maxX= \(maxWidth) y= \(abs(document.emojis[index].y)) maxY= \(maxHeight)")
        return  (abs( document.emojis[index].x) + margin) >= maxWidth ||
                (abs(document.emojis[index].y) + margin) >= maxHeight
                
    }
} // View
