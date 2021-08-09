//
//  Detector.swift
//  MLCamera
//
//  Created by Roi Kedarya on 08/08/2021.
//

import Foundation
import UIKit
import AVFoundation
import MLKit

class Detector {
    
    //MARK:- Properties
    
    var poseDetector: PoseDetector?
    var armsAlreadyRaised = false
    weak var delegate: AudioPlayerProtocol?
    
    static let shared = Detector()
    
    //MARK:- init
    
    private init() {
        setPoseDetector()
    }
    
    func detectVisionImage(_ visionImage: VisionImage) {
        visionImage.orientation = Utilities.imageOrientation()
        if let poseDetector = poseDetector {
            poseDetector.process(visionImage) { [weak self] detectedPoses, error in
                if let error = error {
                    print(error)
                    return
                }
                guard let detectedPoses = detectedPoses, !detectedPoses.isEmpty else {
                    //print("No pose detected.")
                    return
                }
                guard let self = self else { return }
                for pose in detectedPoses {
                    if self.didDetectArmsRaised(pose) {
                        if self.armsAlreadyRaised == false {
                            self.delegate?.playAudio()
                            debugPrint(" 👁👁  arms are raised")
                            self.armsAlreadyRaised = true
                        }
                    } else {
                        if self.armsAlreadyRaised == true {
                            debugPrint("⚠️⚠️⚠️ arms are NOT raised")
                            self.armsAlreadyRaised = false
                        }
                    }
                }
            }
        }
    }
    
    //MARK:- Private methods
    
    private func didDetectArmsRaised(_ pose: Pose) -> Bool {
        let leftElbowLandmark = pose.landmark(ofType: .leftElbow)
        let rightElbowLandmark = pose.landmark(ofType: .rightElbow)
        let rightshoulderLandmark = pose.landmark(ofType: .rightShoulder)
        let leftshoulderLandmark = pose.landmark(ofType: .leftShoulder)
        let leftWristLandmark = pose.landmark(ofType: .leftWrist)
        let rightWristLandmark = pose.landmark(ofType: .rightWrist)
        
        return didSatisfiedConditions(leftElbowLandmark, rightElbowLandmark, leftWristLandmark, rightWristLandmark, leftshoulderLandmark, rightshoulderLandmark)
    }
    
    private func didSatisfiedConditions(_ leftElbow: PoseLandmark, _ rightElbow: PoseLandmark, _ leftWrist: PoseLandmark, _ rightWrist: PoseLandmark, _ leftShoulder: PoseLandmark, _ rightShoulder: PoseLandmark) -> Bool {
        var retVal = false
        let barrier: Float = 0.5
        if leftWrist.inFrameLikelihood > barrier, rightWrist.inFrameLikelihood > barrier, leftElbow.inFrameLikelihood > barrier, rightElbow.inFrameLikelihood > barrier, leftShoulder.inFrameLikelihood > barrier, rightWrist.inFrameLikelihood > barrier {
            
            if leftWrist.position.x < leftElbow.position.x, rightWrist.position.x < rightElbow.position.x,
               leftElbow.position.x < leftShoulder.position.x, rightElbow.position.x < rightShoulder.position.x {
                retVal = true
            }
        }
        return retVal
    }
    
    private func setPoseDetector() {
        let options = AccuratePoseDetectorOptions()
        options.detectorMode = .stream
        poseDetector = PoseDetector.poseDetector(options: options)
    }
}
