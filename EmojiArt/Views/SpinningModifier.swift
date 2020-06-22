//
//  SpinningModifier.swift
//  EmojiArt
//
//  Created by Ulrich Braß on 21.06.20.
//  Copyright © 2020 CS193p Instructor. All rights reserved.
//

import SwiftUI

// make an Image spinning
struct SpinningModifier : ViewModifier {
    @State var isVisible = false
    func body(content : Content) -> some View {
        content
            .rotationEffect(Angle(degrees : isVisible ? 360 : 0))
            .animation(Animation.linear(duration : 1).repeatForever(autoreverses : false))
            .onAppear{self.isVisible = true}
    }
}

extension View {
    func spinning () -> some View {
        self.modifier(SpinningModifier())
    }
}
