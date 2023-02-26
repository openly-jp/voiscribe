import SwiftUI

let UserDefaultRecognitionFrequencySecKey = "recognition-frequency-sec"

struct RecognitionFrequencySecMenuItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "timer.circle.fill")
                .imageScale(.large)
                .frame(width: 32)
            Text(NSLocalizedString("認識頻度", comment: ""))
                .font(.headline)
            Spacer()
        }
    }
}

struct RecognitionFrequencySecSubMenuItemView: View {
    let frequencySec: Int
    @AppStorage(UserDefaultRecognitionFrequencySecKey) var defaultRecognitionFrequencySec = 15

    var body: some View {
        HStack {
            if defaultRecognitionFrequencySec == frequencySec {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
            Text("\(frequencySec)秒")
                .font(.headline)
            Spacer()
        }
        .onTapGesture(perform: {
            if defaultRecognitionFrequencySec != frequencySec {
                defaultRecognitionFrequencySec = frequencySec
            }
        })
    }
}

let recognitionFrequencySecSubMenuItems = [
    MenuItem(view: AnyView(RecognitionFrequencySecSubMenuItemView(frequencySec: 10)), subMenuItems: nil),
    MenuItem(view: AnyView(RecognitionFrequencySecSubMenuItemView(frequencySec: 15)), subMenuItems: nil),
    MenuItem(view: AnyView(RecognitionFrequencySecSubMenuItemView(frequencySec: 30)), subMenuItems: nil),
]

let recognitionFrequencySecMenuItem = MenuItem(
    view: AnyView(RecognitionFrequencySecMenuItemView()),
    subMenuItems: recognitionFrequencySecSubMenuItems
)
