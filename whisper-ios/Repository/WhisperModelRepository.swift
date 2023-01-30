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
    static func fetchWhisperModel(size: Size, language: Lang, needsSubscription _: Bool, callBack: @escaping (URL) throws -> Void) throws -> URL {
        // if model is in bundled resource or in local storage, return it
        if Bundle.main.path(forResource: "ggml-\(size.rawValue).\(language.rawValue)", ofType: "bin") != nil {
            // return the bundled resource path of the model
            let modelUrl = URL(string: Bundle.main.path(forResource: "ggml-\(size.rawValue).\(language.rawValue)", ofType: "bin")!)!
            do {
                try callBack(modelUrl)
            } catch {
                throw NSError(domain: "callBack failed in fetchWhisperModel when the model is in the bundle", code: -1)
            }
            return modelUrl
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("ggml-\(size.rawValue).\(language.rawValue).bin")
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try callBack(destinationURL)
            } catch {
                throw NSError(domain: "callBack failed in fetchWhisperModel when the model is already downloaded", code: -1)
            }
        }
        // if model is not in local storage, download it
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            let modelURL = modelURLs["\(size.rawValue)-\(language.rawValue)"]!
            let url = URL(string: "https://\(modelURL)")!
            let task = URLSession.shared.downloadTask(with: url) { location, _, error in
                guard let location else { return }
                do {
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    try! callBack(destinationURL) // URLSession.shared.downloadTask does not                             allow errors
                } catch {
                    print(error)
                }
            }
            task.resume()
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
