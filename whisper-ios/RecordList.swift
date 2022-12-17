import SwiftUI

struct RecordList: View {
    var body: some View {
        NavigationView {
            List(recordsData) { record in
                NavigationLink(destination: RecordDetails(record: Record())) {
                    VStack(alignment: .leading) {
                        Text(record.name).font(.headline)
                        Text(record.transcription).font(.subheadline)
                    }
                }
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
