//
//  ViewController.swift
//  Speech_to_text
//
//  Created by Matthew Pickett on 11/19/18.
//  Copyright © 2018 Matthew Pickett. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var textView: UITextView!
    
    //recognizes there is  speech in audio
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    //pulls the file whether it is live audio or pre-recorded
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    //puts the two together.
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var audioEngine = AVAudioEngine()
    var lang: String = "en-US"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startButton.isEnabled = false
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .notDetermined:
                isButtonEnabled = false
            case .denied:
                isButtonEnabled = false
            case .restricted:
                isButtonEnabled = false
            }
            OperationQueue.main.addOperation() {
                self.startButton.isEnabled = isButtonEnabled
            }
        }
        
    }
    
    @IBAction func segmentAction(_ sender: Any) {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            lang = "en-US"
            break;
        case 1:
            lang = "es-ES"
            break;
        default:
            lang = "en_US"
            break;
        }
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
    }
    
    
    @IBAction func startAction(_ sender: Any) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startButton.isEnabled = false
            startButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            startButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audio properties not set")
    }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.startButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
            
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("could not start")
        }
    
        textView.text = "Say something, I'm Listening!"
    }
    
    func speechReconizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            startButton.isEnabled = true
        } else {
            startButton.isEnabled = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

