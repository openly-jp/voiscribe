import SwiftUI

struct HomeView: View {
    @State var showSideMenu = false
    @State var page = 0
    var body: some View {
        let drag = DragGesture()
            .onEnded{
                value in
                if value.translation.width < -100 {
                    withAnimation{
                        self.showSideMenu = false
                    }
                }
            }
        VStack{
            ZStack{
                HStack(alignment: .center){
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
                HStack(alignment: .center){
                    Text("Whisper iOS")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            GeometryReader {
                geometry in
                if page == 0 {
                    MainView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: self.showSideMenu ? geometry.size.width * 0.6 : 0)
                        .disabled(self.showSideMenu)
                        .overlay(self.showSideMenu ? Color.black.opacity(0.6) : nil)
                } else if page == 1 {
                    RecognitionTest()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: self.showSideMenu ? geometry.size.width * 0.6 : 0)
                        .disabled(self.showSideMenu)
                        .overlay(self.showSideMenu ? Color.black.opacity(0.6) : nil)
                }
                if self.showSideMenu {
                    SideMenu(page: self.$page)
                        .frame(width: geometry.size.width * 0.6)
                        .transition(.move(edge: .leading))
                }
            }.gesture(self.showSideMenu ? drag : nil)
        }
    }
}

struct MainView: View {
    @State var isRecording: Bool = false
    @State var recognizingSpeechIds: [UUID]
    @State var recognizedSpeeches: [RecognizedSpeech]
    @State var isActives: [Bool]

    init (){
        let initialRecognizedSpeeches = CoreDataRepository.getAllRecognizedSpeeches()
        self.recognizingSpeechIds = []
        self.recognizedSpeeches = initialRecognizedSpeeches
        self.isActives = Array<Bool>(repeating: false, count: initialRecognizedSpeeches.count)
    }
    var body: some View {
        VStack{
            RecordList(
                recognizingSpeechIds: $recognizingSpeechIds,
                recognizedSpeeches: $recognizedSpeeches,
                isActives: $isActives
            )
            RecognitionPane(
                recognizingSpeechIds: $recognizingSpeechIds,
                recognizedSpeeches: $recognizedSpeeches,
                isActives: $isActives
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
