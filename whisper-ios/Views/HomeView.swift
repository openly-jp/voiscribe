import SwiftUI

struct HomeView: View {
    @State var showSideMenu = false
    @AppStorage(UserModeNumKey) var userModeNum = 0
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    HStack(alignment: .center) {
                        Button(action: {
                            self.showSideMenu = !self.showSideMenu
                        }, label: {
                            Image(systemName: "line.horizontal.3")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30, alignment: .center)
                                .foregroundColor(Color.gray)
                        })
                        .padding(.horizontal)
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text(APP_NAME)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }

                GeometryReader {
                    geometry in
                    if userModeNum == 0 {
                        MainView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .disabled(self.showSideMenu)
                            .overlay(self.showSideMenu ? Color.black.opacity(0.6) : nil)
                    } else if userModeNum == 1 {
                        DeveloperMainView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .disabled(self.showSideMenu)
                            .overlay(self.showSideMenu ? Color.black.opacity(0.6) : nil)
                    }

                    SideMenu(isOpen: self.$showSideMenu)
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
