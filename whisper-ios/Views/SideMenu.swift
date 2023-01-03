import SwiftUI

struct SideMenu: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @Binding var page: Int
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Button(action: {
                        do {
                            try recognizer.load_model(modelName: "ggml-tiny.en")
                        } catch {
                            print("model load failed")
                        }
                    }, label: {
                        Text("ggml-tiny.en")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                    Divider()
                    Button(action: {
                        do {
                            try recognizer.load_model(modelName: "ggml-tiny")
                        } catch {
                            print("model load failed")
                        }

                    }, label: {
                        Text("ggml-tiny")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                    Divider()
                    Button(action: {
                        self.page = 1
                    }, label: {
                        Text("認識テスト画面")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                    Divider()
                    Button(action: {
                        self.page = 0
                    }, label: {
                        Text("ユーザー画面")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                }
            } header: {
                Text("開発者メニュー")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listStyle(GroupedListStyle())
    }
}

struct SideMenu_Previews: PreviewProvider {
    @State static var page = 0
    static var previews: some View {
        SideMenu(page: $page)
    }
}
