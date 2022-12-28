import SwiftUI

struct RecordList: View {
    var body: some View {
        NavigationView {
            List(recordsData) { record in
                NavigationLink(destination: RecordDetails(record: record)) {
                    VStack(alignment: .leading) {
                        Text(record.name).font(.headline)
                        Text(record.transcription).font(.subheadline)
                    }
                }
                NavigationLink {
                    RecognitionTest()
                } label: {
                    Label("音声認識テスト", systemImage: "mic.circle.fill").font(.title)
                }.buttonStyle(.borderedProminent)
            }
                    .navigationBarTitle("Recordings")
        }
    }
}

class RecordList_Previews: PreviewProvider {
    static var previews: some View {
        RecordList()
    }

    #if DEBUG
    @objc class func injected() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.rootViewController =
                UIHostingController(rootView: RecordList())
    }
    #endif
}
