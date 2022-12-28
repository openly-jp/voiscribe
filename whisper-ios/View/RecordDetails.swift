import SwiftUI

struct RecordDetails: View {
    var record: Record
    var body: some View {
        VStack(alignment: .leading){
            Text(record.name).padding(.bottom)
            Text(record.date.dateToString()).padding(.bottom)
            Text(String(record.length)).padding(.bottom)
            Text(record.transcription).padding(.bottom)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle(record.name);
    }
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        RecordDetails(record: Record())
    }
    #if DEBUG
    @objc class func injected() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.rootViewController =
                UIHostingController(rootView: RecordDetails(record: Record()))
    }
    #endif
}
