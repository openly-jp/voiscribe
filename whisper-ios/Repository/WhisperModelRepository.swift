import Foundation

let modelURLs: [String: String] = [
    "tiny-multi": "models.openly.jp/ggml-tiny.multi.bin",
    "tiny-en": "models.openly.jp/ggml-tiny.en.bin",
    "base-multi": "models.openly.jp/ggml-base.multi.bin",
    "base-en": "models.openly.jp/ggml-base.en.bin",
    "small-multi": "models.openly.jp/ggml-small.multi.bin",
    "small-en": "models.openly.jp/ggml-small.en.bin",
]

enum WhisperModelRepository {
    /**
     Download a model, if it does exist locally, from R2 and save it to local storage.

     - Parameter size: The size of the model (tiny, base, small).
     - Parameter language: The language of the model (ja, en, multi).
     - Parameter needsSubscription: Whether the model needs a subscription to use.

     - Returns: local path of the model
     */
    static func fetchWhisperModel(size: Size, language: Lang, needsSubscription _: Bool, callBack:@escaping (URL) -> Void) -> URL {
        // if model is in bundled resource or in local storage, return it
        if Bundle.main.path(forResource: "ggml-\(size.rawValue).\(language.rawValue)", ofType: "bin") != nil {
            // return the bundled resource path of the model
            return URL(string: Bundle.main.path(forResource: "ggml-\(size.rawValue).\(language.rawValue)", ofType: "bin")!)!
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("ggml-\(size.rawValue).\(language.rawValue).bin")
        // if model is not in local storage, download it
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            let modelURL = modelURLs["\(size.rawValue)-\(language.rawValue)"]!
            let url = URL(string: "https://\(modelURL)")!
            let task = URLSession.shared.downloadTask(with: url) { location, response, error in
                guard let location else { return }
                do {
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    callBack(destinationURL)
                } catch {
                    print(error)
                }
            }
            task.resume()
        }
        // check if model is downloaded
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("model successfully downloaded at ", destinationURL)
        }
        return destinationURL
    }

    /**
     Delete a model from local storage.

     - Parameter model: The model to delete.
     */
    static func deleteWhisperModel(model: WhisperModel) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(model.localPath!.path)
        try? FileManager.default.removeItem(at: destinationURL)
    }
}