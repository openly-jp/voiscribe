import Foundation

var transcriptionLine11 = TranscriptionLine(startMSec: 0, endMSec: 10000, text: "こんにちは。この音声は日本語のテスト音声です。この音声では日本語における", ordering: 0)
var transcriptionLine12 = TranscriptionLine(startMSec: 10001, endMSec: 2312, text: "音声認識のテストを行います。この音声を用いて認識精度等の確認を行うのが良いでしょう。", ordering: 1)
var transcriptionLines1:[TranscriptionLine] = [transcriptionLine11, transcriptionLine12]
var url1: URL! = Bundle.main.url(forResource: "sample_wav1", withExtension: "wav")

var recognizedSpeech1 = RecognizedSpeech(audioFileURL: url1, language: Language.ja, transcriptionLines: transcriptionLines1)

var transcriptionLine21 = TranscriptionLine(startMSec: 0, endMSec: 201000, text: "Hello. This sound is a english test speech. In this speech, you can check", ordering: 0)
var transcriptionLine22 = TranscriptionLine(startMSec: 201001, endMSec: 2312, text: "the accuracy of english ASR. It will be goot to check accuracy of ASR model.", ordering: 1)
var transcriptionLines2:[TranscriptionLine] = [transcriptionLine21, transcriptionLine22]
var url2: URL! = Bundle.main.url(forResource: "sample_wav2", withExtension: "wav")

var recognizedSpeech2 = RecognizedSpeech(audioFileURL: url2, language: Language.en, transcriptionLines: transcriptionLines2)

var recognizedSpeechMocks: [UUID: RecognizedSpeech] = [
    recognizedSpeech1.id: recognizedSpeech1,
    recognizedSpeech2.id: recognizedSpeech2,
]

