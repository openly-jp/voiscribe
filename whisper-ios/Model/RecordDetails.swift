import SwiftUI

struct RecordDetails: View {
    var record: Record
    var body: some View {
        Text(record.name)
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
