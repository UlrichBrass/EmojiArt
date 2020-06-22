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
