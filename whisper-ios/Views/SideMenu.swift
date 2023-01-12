import SwiftUI

struct SideMenu: View {
    @Binding var isOpen: Bool
    let width: CGFloat = 270
    let menuItems: [MenuItem] = [modelLoadMenuItem, languageSelectMenuItem, developerMenuItem]

    var body: some View {
        ZStack {
            GeometryReader { _ in
                EmptyView()
            }
            .background(Color.gray.opacity(0.3))
            .opacity(self.isOpen ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.25))
            .onTapGesture(perform: {
                self.isOpen = false
            })
            HStack {
                List(menuItems, children: \.subMenuItems) {
                    item in item.view
                }
                .frame(width: width)
                .offset(x: self.isOpen ? 0 : -self.width)
                .animation(.easeIn(duration: 0.25))
                Spacer()
            }
        }
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let view: AnyView
    let subMenuItems: [MenuItem]?
}

struct SideMenu_Previews: PreviewProvider {
    @State static var page = 0
    @State static var isOpen = true
    static var previews: some View {
        SideMenu(isOpen: $isOpen)
    }
}
