//
//  RecordButton.swift
//  whisper-ios
//
//  Created by creevo on 2022/12/29.
//  Copyright © 2022 jp.openly. All rights reserved.
//

import SwiftUI
import AVFoundation


struct RecordButtonPane: View {
    @Binding var isActive: Bool
    let startAction: ()->Void
    let stopAction: ()->Void
    
    @State var buttonColor: Color = .red
    @State var borderStrokeColor: Color = .red
    @State var borderStrokeWidth: CGFloat = 2
    @State var borderSpacing: CGFloat = 10
    @State var animation: Animation = .easeInOut
    @State var stoppedStateCornerRadius: CGFloat = 0.10
    @State var stoppedStateSize: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(borderStrokeColor, lineWidth: borderStrokeWidth)
                .frame(width: 100, height: 100)
            
            recordButton(size: 100 - borderSpacing)
                .animation(animation)
                .foregroundColor(buttonColor)
        }
    }
    
    
    private func recordButton(size: CGFloat) -> some View {
        if !isActive {
            return Button(action: startAction){ RoundedRectangle(cornerRadius: size)
                .frame(width: size, height: size)
                   }
            
        } else {
            return Button(action: stopAction){
                RoundedRectangle(cornerRadius: size * stoppedStateCornerRadius)
                    .frame(width: size * stoppedStateSize, height: size * stoppedStateSize)
            }
            
        }
    }
}

struct RecordButton_Previews: PreviewProvider {
    
    static var previews: some View {
        return RecordButtonPane(isActive: .constant(false), startAction: {}, stopAction: {})
    }
}

