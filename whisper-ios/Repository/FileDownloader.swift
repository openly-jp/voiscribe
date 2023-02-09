import Foundation

class ProgressDelegatee: NSObject, URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        completionHandler(location, downloadTask.response, downloadTask.error)
    }

    let update: (Float) -> Void
    let completionHandler: @Sendable (URL?, URLResponse?, Error?) -> Void

    init(
        update: @escaping (Float) -> Void,
        completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void
    ) {
        self.update = update
        self.completionHandler = completionHandler
    }

    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        update(progress)
    }
}

class FileDownloader {
    private var task: URLSessionDownloadTask?

    func downloadFile(
        withURL url: URL,
        progressHandler: @escaping (_ progress: Float) -> Void,
        completion: @escaping (_ location: URL?, _ error: Error?) -> Void
    ) {
        task = URLSession.shared.downloadTask(with: url)
        task?.delegate = ProgressDelegatee(update: progressHandler) {
            location, response, error in
            if let error {
                completion(nil, error)
                return
            }

            guard let response = response as? HTTPURLResponse,
                  (200 ..< 299).contains(response.statusCode)
            else {
                completion(
                    nil,
                    NSError(
                        domain: "FileDownloaderError", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
                    )
                )
                return
            }

            completion(location, nil)
        }
        task?.resume()
    }

    func cancelDownload() {
        task?.cancel()
    }
}
