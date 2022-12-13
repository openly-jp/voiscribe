import SwiftUI

struct RecordDetails: View {
    var body: some View {
        Text("Hello World")
    }
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        RecordDetails()
    }
    #if DEBUG
    @objc class func injected() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.rootViewController =
                UIHostingController(rootView: RecordDetails())
    }
    #endif
}
