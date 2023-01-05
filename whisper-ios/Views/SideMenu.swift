import SwiftUI

struct SideMenu: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @Binding var page: Int
    @Binding var isOpen: Bool
    let width: CGFloat = 270
    let menuItems: [MenuItem] = [modelLoadMenuItem]
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                EmptyView()
            }
            .background(Color.gray.opacity(0.3))
            .opacity(self.isOpen ? 1.0 : 0.0)
            .animation(.easeIn(duration: 0.25))
            .onTapGesture(perform: {
                self.isOpen = false
            })
            HStack{
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



private struct SideMenuItemView: View {
    let systemName: String
    let text: String
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .imageScale(.large)
                .frame(width: 32)
            Text(text)
                .font(.headline)
            Spacer()
        }
        .padding(.leading, 16)
    }
}


struct SideMenu_Previews: PreviewProvider {
    @State static var page = 0
    @State static var isOpen = true
    static var previews: some View {
        SideMenu(page: $page, isOpen: $isOpen)
    }
}
