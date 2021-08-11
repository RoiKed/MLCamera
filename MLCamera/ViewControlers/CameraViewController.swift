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
    private var backCamera: AVCaptureDevice!
    private var frontCamera : AVCaptureDevice!
    private var backInput : AVCaptureInput!
    private var frontInput : AVCaptureInput!
    var backCameraOn = true
    
    let switchCameraButton : UIButton = {
        let button = UIButton()
        let image = UIImage(named: "switchcamera")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
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
    
    func switchCameraInput() {
        switchCameraButton.isUserInteractionEnabled = false
        //reconfigure the input
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
        videoOutput.connections.first?.isVideoMirrored = false
        captureSession.commitConfiguration()
        switchCameraButton.isUserInteractionEnabled = true
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
        setupInputs()
        setCameraButton()
        setRecordButton()
        setPreviewLayer()

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func setupInputs() {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
            setupCamera(camera: backCamera)
        } else {
            fatalError("no back camera")
        }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }
        
        guard let backInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        self.backInput = backInput
        guard let frontInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        self.frontInput = frontInput
        
        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }
        if captureSession.canAddInput(backInput) {
            captureSession.addInput(backInput)
        } else {
            fatalError("could not add back camera input to capture session")
        }
    }
    
    private func setupCamera(camera:AVCaptureDevice) {
        try? camera.lockForConfiguration()
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
            camera.videoZoomFactor = 1
            camera.unlockForConfiguration()
        }
    }
    
    private func setDetector() {
        detector = Detector.shared
        detector?.delegate = self
    }
    
    private func setCameraButton() {
        view.addSubview(switchCameraButton)
        NSLayoutConstraint.activate([
            switchCameraButton.widthAnchor.constraint(equalToConstant: 30),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 30),
            switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
        
        switchCameraButton.addTarget(self, action: #selector(switchCamera(_:)), for: .touchUpInside)
    }
    
    @objc func switchCamera(_ sender: UIButton?){
        switchCameraInput()
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

