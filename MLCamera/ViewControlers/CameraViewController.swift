//
//  CameraViewController.swift
//  MLCamera
//
//  Created by Roi Kedarya on 07/08/2021.
//

import UIKit
import AVFoundation
import ReplayKit
import MLKit


class CameraViewController: UIViewController {
    
    //MARK:- Properties
    
    @IBOutlet weak var previewView: UIView!
    private let captureSession = AVCaptureMultiCamSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var detector: Detector?
    private let recorder = RPScreenRecorder.shared()
    private var captureDevice: AVCaptureDevice?
    private var image: UIImage?
    
    let recordButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .red
        button.tintColor = .white
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var audioPlayer: AVAudioPlayer? = {
        let path = Bundle.main.path(forResource: "dundundun", ofType:"wav")!
        let url = URL(fileURLWithPath: path)
        let audioPlayer = try? AVAudioPlayer(contentsOf: url)
        return audioPlayer
    }()
    
    //MARK:- ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDetector()
        setCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    //MARK:- IBActions
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        recordButton.isSelected = !recordButton.isSelected
        shouldSetVideoOutputDelegate(recordButton.isSelected)
        if recordButton.isSelected {
            recordButton.layer.cornerRadius = 0
            startRecording()
        } else {
            recordButton.layer.cornerRadius = 25
            stopRecording()
        }
    }
    
    
    //MARK:- Private methods
    
    private func setPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewView.layer.insertSublayer(previewLayer, below: recordButton.layer)
        previewLayer.frame = previewView.layer.bounds
    }
    
    private func shouldSetVideoOutputDelegate(_ shouldSet: Bool) {
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        if shouldSet {
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        } else {
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
        }
    }
    
    private func setCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        self.captureDevice = captureDevice
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        setRecordButton()
        setPreviewLayer()

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func setDetector() {
        detector = Detector.shared
        detector?.delegate = self
    }
    
    private func setRecordButton() {
        view.addSubview(recordButton)
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10),
            recordButton.widthAnchor.constraint(equalToConstant: 50),
            recordButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func startRecording() {
        recorder.startRecording { error in
            if let error = error {
                print(error)
            }
        }
    }
    
    private func stopRecording() {
        recorder.stopRecording { previewViewController, error in
            if let error = error {
                print(error)
            }
            if let previewViewController = previewViewController {
                previewViewController.previewControllerDelegate = self
                self.present(previewViewController, animated: true, completion: nil)
            }
        }
    }
}
//MARK:- AudioPlayerProtocol
extension CameraViewController: AudioPlayerProtocol {
    func playAudio() {
        self.audioPlayer?.play()
    }
}

//MARK:- RPPreviewViewControllerDelegate
extension CameraViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK:- AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let visionImage = VisionImage(buffer: sampleBuffer)
        if let detector = detector {
            detector.detectVisionImage(visionImage)
        }
    }
}

