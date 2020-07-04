//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Ulrich Braß on 03.07.20.
//  Copyright © 2020 CS193p Instructor. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store : EmojiArtDocumentStore
    @State var editMode : EditMode = .inactive
    
    var body: some View {
        NavigationView{
            List{
                ForEach(store.documents){document in
                    NavigationLink(
                        destination : EmojiArtDocumentView().environmentObject(document).navigationBarTitle(self.store.name(for: document))
                    ){
                        EditableText(self.store.name(for : document), isEditing : self.editMode.isEditing){ name in
                            self.store.setName(name, for: document)
                        }
                    } //Navigation Link
                    
                } //ForEach
                .onDelete{indexSet in
                    indexSet.map {self.store.documents[$0]}
                        .forEach{document in
                            self.store.removeDocument(document)
                    }
                }
            } //List
            .navigationBarTitle(store.name)
            .navigationBarItems(leading: Button(    action: {self.store.addDocument()},
                                                    label: {Image(systemName: "plus").imageScale(.large)}
                                                ),
                                trailing : EditButton()
            )
                .environment(\.editMode, $editMode) // apllies to binding with EditButton only
        } //NavigationView
    } //body
} // View

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
