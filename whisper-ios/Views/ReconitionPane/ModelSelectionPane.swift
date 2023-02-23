import SwiftUI

struct ModelSelectionPane: View {
    var body: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 30)
            HStack {
                Text("モデル選択")
                    .font(.title)
                    .fontWeight(.bold)
                    // this force the alignment center
                    .frame(maxWidth: .infinity)
            }
            ForEach(Size.allCases) { size in
                ModelSelectionRow(modelSize: size)
                Divider()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ModelSelectionRow: View {
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize = Size(rawValue: "tiny")!
    let modelSize: Size
    var body: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Text(modelSize.displayName)
                    .frame(minWidth: 50, minHeight: 50)
                    .font(.title2)
                    .padding()
                    .background(Color(uiColor: .systemGray5).opacity(0.8))
                    .cornerRadius(20)
                if modelSize == defaultModelSize {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .offset(x: 5)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .green)
                }
            }
            VStack(alignment: .leading) {
                HStack {
                    Text("精度")
                        .frame(minWidth: 30)
                    Group {
                        ForEach(0 ..< modelSize.accuracy) { _ in
                            Image(systemName: "star.fill")
                                .frame(width: 25)
                        }
                        ForEach(0 ..< 5 - modelSize.accuracy) { _ in
                            Image(systemName: "star")
                                .frame(width: 25)
                        }
                    }
                }
                HStack {
                    Text("速度")
                        .frame(minWidth: 30)
                    ForEach(0 ..< modelSize.speed) { _ in
                        Image(systemName: "car.side.fill")
                            .frame(width: 25)
                    }
                    ForEach(0 ..< 5 - modelSize.speed) { _ in
                        Image(systemName: "car.side")
                            .frame(width: 25)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            defaultModelSize = modelSize
        }
    }
}

struct ModelSelectionPane_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionPane()
    }
}
