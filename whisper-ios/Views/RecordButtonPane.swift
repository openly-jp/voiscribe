//
//  RecordButton.swift
//  whisper-ios
//
//  Created by creevo on 2022/12/29.
//  Copyright © 2022 jp.openly. All rights reserved.
//

import AVFoundation
import SwiftUI

struct RecordButtonPane: View {
    @Binding var isRecording: Bool
    @Binding var isPaused: Bool

    let startAction: () -> Void
    let stopAction: () -> Void

    let circleDiameter: CGFloat = 80
    let buttonColor: Color = .red
    let borderStrokeColor: Color = .red
    let borderStrokeWidth: CGFloat = 2
    let borderSpacing: CGFloat = 10
    let stoppedStateCornerRadius: CGFloat = 0.10
    let stoppedStateSize: CGFloat = 0.5

    var body: some View {
        ZStack {
            if isRecording && !isPaused {
                Circle()
                    .stroke(.gray, lineWidth: borderStrokeWidth)
                    .frame(width: circleDiameter, height: circleDiameter)
                Button(action: stopAction) {
                    Image(systemName: "pause.fill")
                        .resizable()
                        .frame(width: circleDiameter / 3, height: circleDiameter / 3)
                        .foregroundColor(.gray)
                }

            } else {
                Circle()
                    .stroke(borderStrokeColor, lineWidth: borderStrokeWidth)
                    .frame(width: circleDiameter, height: circleDiameter)

                let size = circleDiameter - borderSpacing
                Button(action: startAction) { RoundedRectangle(cornerRadius: size)
                        .frame(width:  size, height: size)
                        .foregroundColor(buttonColor)
                }
            }
        }
    }
}

struct RecordButton_Previews: PreviewProvider {
    static var previews: some View {
        return RecordButtonPane(
            isRecording: .constant(false),
            isPaused: .constant(false),
            startAction: {},
            stopAction: {}
        )
    }
}
