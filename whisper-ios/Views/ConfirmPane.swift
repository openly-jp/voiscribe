import SwiftUI

struct ConfirmPane: View {
    let finishRecording: () -> Void
    let abortRecording: () -> Void

    @Binding var title: String

    var body: some View {
        VStack {
            Text("録音を終了しますか？")
                .bold()
                .font(.title)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 40) {
                TextField(NSLocalizedString("タイトル", comment: ""), text: $title)
                    .font(.title3)
                HStack(spacing: 30) {
                    Button("録音中止", action: abortRecording)
                        .foregroundColor(.red)
                    Spacer()
                    Button("終了", action: finishRecording)
                        .padding()
                        .accentColor(Color(.label))
                        .background(Color(.systemGray4))
                        .cornerRadius(5)
                        .colorInvert()
                }.padding(.top, 50)
            }
            .padding(.horizontal, 70)
        }
    }
}

struct ConfirmPane_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmPane(
            finishRecording: {},
            abortRecording: {},
            title: .constant(NSLocalizedString("タイトル", comment: ""))
        )
    }
}
