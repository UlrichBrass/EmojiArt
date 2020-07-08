//
//  EmojiArtDocumentStore.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 5/6/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import Combine

// View Model which holds references to other view models
// This will allow us to have more than one background document
class EmojiArtDocumentStore: ObservableObject
{
    // Management of references to EmijiArtDocument view models
    @Published private var documentNames = [EmojiArtDocument:String]()
    
    let name: String
    
    func name(for document: EmojiArtDocument) -> String {
        if documentNames[document] == nil {
            documentNames[document] = "Untitled"
        }
        return documentNames[document]!
    }
    
    func setName(_ name: String, for document: EmojiArtDocument) {
        // the following if let ensures, that the function works for both User defaults and file system
        if let url = directory?.appendingPathComponent(name){
            // check if name already exists. If so ignore request
            if !documentNames.values.contains(name) {
                removeDocument(document)
                document.url = url
                documentNames[document] = name
            } 
        } else {
            documentNames[document] = name
        }
    }
    
    var documents: [EmojiArtDocument] {
        documentNames.keys.sorted { documentNames[$0]! < documentNames[$1]! }
    }
    
    func addDocument(named name: String = "Untitled") {
        // documents stored in the file system have to have unique names
        let uniqueName = name.uniqued(withRespectTo: documentNames.values)
        let document : EmojiArtDocument
        // the following if let ensures, that the function works for both User defaults and file system
        if let url = directory?.appendingPathComponent(uniqueName){
            document = EmojiArtDocument(url: url)
        } else {
            document = EmojiArtDocument()
        }
        documentNames[document] = uniqueName
    }

    func removeDocument(_ document: EmojiArtDocument) {
        if let name = documentNames[document], let url = directory?.appendingPathComponent(name){
            try? FileManager.default.removeItem(at: url)
        }
        documentNames[document] = nil
    }
    
   
    // autosave in User defaults document store
    private var autosave: AnyCancellable?
    
    init(named name: String = "Emoji Art") {
        self.name = name
        let defaultsKey = "EmojiArtDocumentStore.\(name)"
        documentNames = Dictionary(fromPropertyList: UserDefaults.standard.object(forKey: defaultsKey))
        autosave = $documentNames.sink { names in
            UserDefaults.standard.set(names.asPropertyList, forKey: defaultsKey)
        }
    }
    
    // keep the existing implementation for storing documents in user defaults, but providing an equivalent
    // for file system storage in the sandbox environment of the application
    init(directory : URL, named name: String = "Emoji Art"){
        self.name = name
        self.directory = directory
        do {
            // get the names of all the files in the sandbox directory
            let documents = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            // go through the list
            for document in documents {
                // create EmojiArtDocument with full path name
                let emojiArtdocument = EmojiArtDocument(url: directory.appendingPathComponent(document))
                // add to dictionary
                self.documentNames[emojiArtdocument] = document
            }
        }
        catch {
            print("EmojiArtDucumentStore: could not create store from director \(directory): error \(error.localizedDescription)")
        }
    }
    
    private var directory : URL?
}
//Extensions for conversion of Dictionary to property list
extension Dictionary where Key == EmojiArtDocument, Value == String {
    var asPropertyList: [String:String] {
        var uuidToName = [String:String]()
        for (key, value) in self {
            uuidToName[key.id.uuidString] = value
        }
        return uuidToName
    }
    
    init(fromPropertyList plist: Any?) {
        self.init()
        let uuidToName = plist as? [String:String] ?? [:]
        for uuid in uuidToName.keys {
            self[EmojiArtDocument(id: UUID(uuidString: uuid))] = uuidToName[uuid]
        }
    }
}
