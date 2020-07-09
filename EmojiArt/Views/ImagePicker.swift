//
//  ImagePicker.swift
//  EmojiArt
//
//  Created by Ulrich Braß on 09.07.20.
//  Copyright © 2020 CS193p Instructor. All rights reserved.
//

import SwiftUI
import UIKit

// A UIViewControllerRepresentable turns a controller into a SwiftUI View
// UIViewControllerRepresentable are SwiftUI Views They have 5 main components ...

struct ImagePicker : UIViewControllerRepresentable  {
    var sourceType : UIImagePickerController.SourceType
    // a function which creates the UIKit controller
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController ()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator // instance created by makeController
        
        return picker
    }
    // a function which updates the UIKit controller when appropriate (bindings change, etc.)
    func updateUIViewController(_ uiViewController : UIImagePickerController, context: Context) {
        
    }
    
    // a Coordinator object which handles any delegate activity that goes on
    func makeCoordinator() -> Coordinator { // Coordinator is a don’t care for Representables
        return Coordinator(handlePickedImage : self.handlePickedImage)
    }
    
    class Coordinator : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var handlePickedImage : pickedImageHandler
        init(handlePickedImage : @escaping pickedImageHandler) {
            self.handlePickedImage = handlePickedImage
        }
        // pick an image from photo library or camera
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            handlePickedImage(info[.originalImage] as? UIImage)
        }
        // cancel controller
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            handlePickedImage(nil)
        }
    }
    
    // Callback handling
    typealias pickedImageHandler = (UIImage?) -> Void
    var handlePickedImage : pickedImageHandler
} //ImagePicker
