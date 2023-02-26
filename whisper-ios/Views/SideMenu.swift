import SwiftUI

let sideMenuWidth: CGFloat = 270
let sideMenuOpenOffset: CGFloat = 0
let sideMenuCloseOffset: CGFloat = -1 * sideMenuWidth

//  let localeIdentifiers = ["en-US", "en-GB", "fr-FR", "ja-JP", "ja-US", "es-ES"]
//  let uniqueLanguageCodes = Set(localeIdentifiers.map { Locale(identifier: $0).languageCode })
//  print(uniqueLanguageCodes)
//  Output: ["en", "fr", "ja", "es"]
let uniqueLanguageCodes = Set(NSLocale.preferredLanguages.map { Locale(identifier: $0).languageCode })

struct SideMenu: View {
    @Binding var isOpen: Bool
    @Binding var offset: CGFloat

    let menuItems: [MenuItem] =
        uniqueLanguageCodes.count > 1 ?
        [
            modelLoadMenuItem,
            recognitionFrequencySecMenuItem,
            languageSelectMenuItem,
            appInfoMenuItem,
            displayedLanguageSwitchMenuItem,
        ] :
        [
            modelLoadMenuItem,
            recognitionFrequencySecMenuItem,
            languageSelectMenuItem,
            appInfoMenuItem,
        ]

    var body: some View {
        GeometryReader {
            _ in
            ZStack {
                GeometryReader { _ in
                    EmptyView()
                }
                // background and opacity is needed for activating onTapGesture
                .background(Color.gray.opacity(0.1))
                .opacity(isOpen ? 1 : 0)
                .onTapGesture(perform: {
                    offset = sideMenuCloseOffset
                    isOpen = false
                })
                HStack {
                    List(menuItems, children: \.subMenuItems) {
                        item in item.view
                    }
                    .frame(width: sideMenuWidth)
                    .offset(x: offset)
                    .animation(.default)
                    Spacer()
                }
            }
            .gesture(isOpen ? DragGesture()
                .onChanged {
                    value in
                    if value.translation.width < 0 {
                        offset = max(sideMenuCloseOffset, sideMenuOpenOffset - abs(value.translation.width))
                    }
                }
                .onEnded { _ in
                    if offset < 0.5 * sideMenuCloseOffset {
                        offset = sideMenuCloseOffset
                        isOpen = false
                    } else {
                        offset = sideMenuOpenOffset
                    }
                } : nil)
        }
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let view: AnyView
    let subMenuItems: [MenuItem]?
}

struct SideMenu_Previews: PreviewProvider {
    @State static var isOpen = true
    @State static var offset: CGFloat = 0
    static var previews: some View {
        SideMenu(isOpen: $isOpen, offset: $offset)
    }
}
