import Foundation
import SwiftUI


/// use with views used as the destination of navigationLink
///
/// motivation: https://note.com/kauche/n/n09ed8b640ac6#d65484fd-3bd0-4ba4-8074-4854ecee82fd
/// source: https://gist.github.com/chriseidhof/d2fcafb53843df343fe07f3c0dac41d5
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
