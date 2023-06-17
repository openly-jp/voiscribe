import Foundation

let modelURLs: [String: String] = [
    "base-multi": "models.openly.jp/ggml-base.q8_0.bin",
    "base-en": "models.openly.jp/ggml-base.en.q8_0.bin",
    "small-multi": "models.openly.jp/ggml-small.q8_0.bin",
    "small-en": "models.openly.jp/ggml-small.en.q8_0.bin",
    "medium-multi": "models.openly.jp/ggml-medium.q8_0.bin",
    "medium-en": "models.openly.jp/ggml-medium.en.q8_0.bin",
]

enum WhisperModelRepository {
    /// Download a model, if it does exist locally, from R2 and save it to local storage.
    /// - Parameter size: The size of the model (tiny, base, small).
    /// - Parameter language: The language of the model (ja, en, multi).
    /// - Returns: local path of the model
    static func fetchWhisperModel(
        size: Size,
        language: ModelLanguage,
        update: ((Float) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // if model is in bundled resource or in local storage, return it
        let path = Bundle.main.path(
            forResource: "ggml-\(size.rawValue).\(language.rawValue)",
            ofType: "bin"
        )
        if path != nil {
            // return the bundled resource path of the model
            let modelUrl = URL(string: Bundle.main
                .path(forResource: "ggml-\(size.rawValue).\(language.rawValue)", ofType: "bin")!)!
            completion(.success(modelUrl))
            return
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("ggml-\(size.rawValue).\(language.rawValue).bin")
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            completion(.success(destinationURL))
            return
        }

        let fileDownloader = FileDownloader()
        let modelURL = modelURLs["\(size.rawValue)-\(language.rawValue)"]!
        let url = URL(string: "https://\(modelURL)")!
        fileDownloader.downloadFile(withURL: url, progressHandler: { progress in
            if update != nil {
                update!(progress)
            }
            print("Download progress: \(Int(progress * 100))%")
        }) { location, error in
            if error == nil {
                print("File download was successful")
                try? FileManager.default.moveItem(at: location!, to: destinationURL)

                completion(.success(destinationURL))
            } else {
                print("File download failed with error: \(error!.localizedDescription)")
                completion(.failure(error!))
            }
        }
    }

    /// Delete a model from local storage.
    /// - Parameter model: The model to delete.
    static func deleteWhisperModel(size: Size, language: ModelLanguage) -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("ggml-\(size.rawValue).\(language.rawValue).bin")
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            print("Designated file does not exist.")
            return false
        }
        do {
            try FileManager.default.removeItem(at: destinationURL)
            return true
        } catch {
            print("model deletion failed with error: \(error.localizedDescription)")
            return false
        }
    }
}
