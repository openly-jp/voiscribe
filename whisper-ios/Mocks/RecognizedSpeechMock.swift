import Foundation

func loadTranscriptionLinesFromCSV(fileName: String) -> [TranscriptionLine] {
    var transcriptionLines: [TranscriptionLine] = []
    guard let csvFilePath = Bundle.main.path(forResource:fileName, ofType:"csv") else {
        return transcriptionLines
    }
    guard let csvString  = try? String(contentsOfFile: csvFilePath, encoding: String.Encoding.utf8) else {
        return transcriptionLines
    }
    let csvArray = csvString.components(separatedBy: "\n")
    for (index, line) in csvArray.enumerated() {
        let parts = line.components(separatedBy: ",")
        guard let startSec = Int64(parts[0]) else{
            continue
        }
        guard let endSec = Int64(parts[1]) else {
            continue
        }
        let text = parts[2]
        let transcriptionLine = TranscriptionLine(startMSec: startSec * 1000, endMSec: endSec * 1000, text: text, ordering: Int32(index))
        transcriptionLines.append(transcriptionLine)
    }
    return transcriptionLines
}

func getRecognizedSpeechMock(audioFileName: String, csvFileName: String) -> RecognizedSpeech? {
    guard let audioFileURL: URL = Bundle.main.url(forResource: audioFileName, withExtension: "wav") else {
        return nil
    }
    let transcriptionLines = loadTranscriptionLinesFromCSV(fileName: csvFileName)
    
    return RecognizedSpeech(audioFileURL: audioFileURL, language: Language.ja, transcriptionLines: transcriptionLines)
}



