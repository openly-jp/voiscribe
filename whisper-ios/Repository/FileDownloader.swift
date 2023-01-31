import Foundation

class FileDownloader {
    private var task: URLSessionDownloadTask?
    private var progress: Float = 0.0

    func downloadFile(
        withURL url: URL,
        progress: @escaping (_ progress: Float) -> Void,
        completion: @escaping (_ location: URL?, _ success: Bool, _ error: Error?) -> Void
    ) {
        task = URLSession.shared.downloadTask(with: url) { location, response, error in
            if let error {
                completion(nil, false, error)
                return
            }

            guard let response = response as? HTTPURLResponse, (200 ..< 299).contains(response.statusCode) else {
                completion(
                    nil,
                    false,
                    NSError(domain: "FileDownloaderError", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                )
                return
            }

            completion(location, true, nil)
        }
        task?.resume()

        let interval = 1.0 / 30.0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if self.task?.state == .completed {
                timer.invalidate()
            } else {
                let newProgress = Float(self.task!.countOfBytesReceived) /
                    Float(self.task!.countOfBytesExpectedToReceive)
                if newProgress > self.progress {
                    self.progress = newProgress
                    progress(newProgress)
                }
            }
        }
    }

    func cancelDownload() {
        task?.cancel()
    }
}
