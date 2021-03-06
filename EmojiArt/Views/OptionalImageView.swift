//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/29/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// Handle UIImage, that might be nil
struct OptionalImageView: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
