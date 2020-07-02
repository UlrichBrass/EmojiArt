//
//  PaletteEditorView.swift
//  EmojiArt
//
//  Created by Ulrich Braß on 23.06.20.
//  Copyright © 2020 CS193p Instructor. All rights reserved.
//

import SwiftUI

// The Palette Editor
struct PaletteEditorView: View {
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var chosenPalette : String
    @State var paletteName : String  = ""
    @State var emojisToAdd : String  = ""
    var body: some View {
        VStack (spacing : 0){
            Text("Palette Editor")
                .font(.headline)
                .padding()
            Divider()
            // Form is automatically scrollable, and does all the layout
            Form {
                Section{
                    // Theme name editing
                    TextField("Palette Name:", text : $paletteName, onEditingChanged : { began in
                            // we want to change the palette name in the palleteChooserView only if editing ended (== !began)
                        if !began {}
                            self.document.renamePalette(self.chosenPalette, to: self.paletteName)
                            }
                        )
                
                    // Emoji adding
                    TextField("Add Emoji:", text : $emojisToAdd, onEditingChanged : { began in
                            // we want to add emojis in the palleteChooserView only if editing ended (== !began)
                        if !began {}
                            self.chosenPalette = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPalette)
                            self.emojisToAdd = ""
                            }
                        )
                } // Section
                Section(header : Text("Remove Emoji")){
                    // Use GridView from Memorize (with change to accept 'id'), to show Emojis more compact
                    GridView(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size : self.fontSize))
                                .onTapGesture {
                                   self.chosenPalette = self.document.removeEmoji(emoji, fromPalette: self.chosenPalette)
                            }
                        } // GridView
                        .frame(height : self.height)
                } // Section
            } // Form
        } // VStack
            .onAppear{
                self.paletteName = self.document.paletteNames[self.chosenPalette] ?? ""
            }
    } // body
    
    // MARK: - Drawing Constants
    var height : CGFloat{
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }
    
    let fontSize : CGFloat = 40
} // View

struct PaletteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        PaletteEditorView(chosenPalette: Binding.constant(""))
    }
}
