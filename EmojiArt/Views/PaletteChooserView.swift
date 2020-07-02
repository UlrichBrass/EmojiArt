//
//  PaletteChooserView.swift
//  EmojiArt
//
//  Created by Ulrich Braß on 22.06.20.
//  Copyright © 2020 CS193p Instructor. All rights reserved.
//

import SwiftUI

struct PaletteChooserView : View {
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var chosenPalette : String
    @State var showPaletteEditor : Bool = false
    var body: some View {
        HStack {
            Stepper(onIncrement: {
                        self.chosenPalette = self.document.palette(after: self.chosenPalette)
                },
                    onDecrement: {
                        self.chosenPalette = self.document.palette(before: self.chosenPalette)
                },
                    label: {
                        EmptyView() // No label needed
                    }
            )
            Text(self.document.paletteNames[self.chosenPalette] ?? "")
            // starting Palette Edititor tool
            Image(systemName: "keyboard")
                .onTapGesture {
                    self.showPaletteEditor = true
            }
                .imageScale(.large)
                // .popover opens a new window pointing to where it was opened from.
                // Instead .sheet could be use, but may appear too large. For actual usage see Memorize
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditorView(chosenPalette : self.$chosenPalette) // applying $ to binding returns self
                        // give popover a minimum size
                        .frame(minWidth : 300, minHeight: 500)
                        // .environmentObject is needed because a view is called from within .popover
                        .environmentObject(self.document)
                    // popover will set showPaletteEditor back to false, once clicked outside the box
                }
        } // HStack
            // size to fit without any extra space
            .fixedSize(horizontal: true, vertical: false)
           
    } // body
} // View


struct PaletteChooserView_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooserView(chosenPalette: Binding.constant(""))
    }
}
