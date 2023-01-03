//
//  Waveform.swift
//  whisper-ios
//
//  Created by creevo on 2023/01/01.
//  Copyright © 2023 jp.openly. All rights reserved.
//

import SwiftUI

struct IdAmp: Identifiable {
    var id: UUID
    var amp: Float
    var idx: Int
}

struct Waveform: View {
    @Binding var idAmps: [IdAmp]

    let e: Float = 2.718281828459
    let rectangleWidth: CGFloat = 2.0
    let spacingWidth: CGFloat = 2.0

    var body: some View {
        GeometryReader { geometry in
            Group {
                ForEach(idAmps) { idAmp in
                    let amp = CGFloat(powf(e, idAmp.amp / 10) * 2)

                    let numRightRecs = CGFloat(idAmps.count - 1 - idAmp.idx)
                    let rightX = numRightRecs * (rectangleWidth + spacingWidth)
                    Rectangle()
                        .frame(width: rectangleWidth, height: amp * 50)
                        .position(x: geometry.size.width - rightX)
                }
            }
        }
    }
}

struct Waveform_Previews: PreviewProvider {
    static var previews: some View {
        var idAmps: [IdAmp] = []
        var idx = 0
        for amp in [-50, -2, -14, -14, -11, -42, -21, -100, -14] {
            idAmps.append(IdAmp(id: UUID(), amp: Float(amp), idx: idx))
            idx += 1
        }
        return Waveform(idAmps: .constant(idAmps))
    }
}
