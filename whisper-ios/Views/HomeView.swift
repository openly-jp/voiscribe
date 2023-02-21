import AVFoundation
import SwiftUI

struct HomeView: View {
    @State var showSideMenu = false
    @State var fileContent: Data = .init()
    @State var showDocumentPickerAudio = false
    @State var showDocumentPickerNote = false
    @State var sideMenuOffset = sideMenuCloseOffset
    @AppStorage(UserModeNumKey) var userModeNum = 0

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    HStack(alignment: .center) {
                        Button(action: {
                            sideMenuOffset = showSideMenu ? sideMenuCloseOffset : sideMenuOpenOffset
                            showSideMenu.toggle()
                        }, label: {
                            Image(systemName: "line.horizontal.3")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30, alignment: .center)
                                .foregroundColor(Color.gray)
                        })
                        .padding(.horizontal)
                        Spacer()
                        Menu {
                            Button(
                                action: { showDocumentPickerNote = true },
                                label: { Label("ノートファイルをインポート", systemImage: "note.text") }
                            )
                            Button(
                                action: { showDocumentPickerAudio = true },
                                label: { Label("音声ファイルをインポート", systemImage: "waveform") }
                            )
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 27, height: 27, alignment: .center)
                                .foregroundColor(Color.gray)
                        }
                        .sheet(isPresented: self.$showDocumentPickerAudio) {
                            DocumentPicker(
                                fileContent: $fileContent,
                                fileformat: ".audio"
                            )
                        }
                        .sheet(isPresented: self.$showDocumentPickerNote) {
                            DocumentPicker(
                                fileContent: $fileContent,
                                fileformat: ".text"
                            )
                        }
                        Spacer().frame(width: 20)
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
                            .disabled(showSideMenu)
                            .overlay(showSideMenu ? Color.black.opacity(0.6) : nil)
                    } else if userModeNum == 1 {
                        DeveloperMainView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .disabled(showSideMenu)
                            .overlay(showSideMenu ? Color.black.opacity(0.6) : nil)
                    }

                    SideMenu(isOpen: $showSideMenu, offset: $sideMenuOffset)
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileContent: Data
    var fileformat: String

    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(fileContent: $fileContent)
    }

    func makeUIViewController(context:
        UIViewControllerRepresentableContext<DocumentPicker>) ->
        UIDocumentPickerViewController
    {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _: UIDocumentPickerViewController,
        context _: UIViewControllerRepresentableContext<DocumentPicker>
    ) {
        Logger.info("update")
        Logger.info(fileContent.count)
    }
}

// class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
//
//    @Binding var fileContent: Data
//
//    init(fileContent: Binding<Data>) {
//        _fileContent = fileContent
//    }
//
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        guard let audioURL = urls.first else {
//            return
//        }
//
//        do {
//            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
//            appropriateFor: nil, create: true)
//            let destinationURL =
//            documentsURL.appendingPathComponent("MyAudioFiles").appendingPathComponent(audioURL.lastPathComponent)
//            try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(),
//            withIntermediateDirectories: true, attributes: nil)
//            try FileManager.default.copyItem(at: audioURL, to: destinationURL)
//            let audioData = try Data(contentsOf: destinationURL)
//            fileContent = audioData
//        } catch {
//            print("Error copying audio file: \(error)")
//        }
//    }
// }

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @State var recognizingSpeech: RecognizedSpeech?

    @Binding var fileContent: Data

    init(fileContent: Binding<Data>) {
        _fileContent = fileContent
    }

    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let fileURL = urls[0]

        let certData = try! Data(contentsOf: fileURL)

        if let documentsPathURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            let certURL = documentsPathURL.appendingPathComponent("certFile.pfx")

            try? certData.write(to: certURL)

            postProcessRecordings()
        }
    }

    func postProcessRecordings() {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDirectory = documentsUrl.appendingPathComponent("recordings")

        do {
            let directoryContents = try fileManager.contentsOfDirectory(
                at: recordingsDirectory,
                includingPropertiesForKeys: nil
            )

            for recording in directoryContents {
                let recordingFilename = recording.lastPathComponent
                let recordingExtension = recording.pathExtension
                if recordingExtension == "m4a" {
                    let outputFilename = recordingFilename.replacingOccurrences(of: ".m4a", with: ".wav")
                    let outputFileURL = recordingsDirectory.appendingPathComponent(outputFilename)

                    let asset = AVURLAsset(url: recording)
                    let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
                    exportSession?.outputFileType = AVFileType.wav
                    exportSession?.outputURL = outputFileURL

                    exportSession?.exportAsynchronously(completionHandler: {
                        if exportSession?.status == AVAssetExportSession.Status.completed {
                            do {
                                try fileManager.removeItem(at: recording)
                            } catch {
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    })
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
