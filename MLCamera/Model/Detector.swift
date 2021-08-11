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
    
    /*
     The X axis points to the right
     The Y axis points down
     */
    private func didSatisfiedConditions(_ leftElbow: PoseLandmark, _ rightElbow: PoseLandmark, _ leftWrist: PoseLandmark, _ rightWrist: PoseLandmark, _ leftShoulder: PoseLandmark, _ rightShoulder: PoseLandmark) -> Bool {
        var retVal = false
        if landmarksAreInFrame(leftElbow, rightElbow, leftWrist, rightWrist, leftShoulder, rightShoulder) {
            if leftShoulder.position.y >= leftElbow.position.y && rightShoulder.position.y >= rightElbow.position.y,
               leftShoulder.position.x < leftElbow.position.x && rightShoulder.position.x > rightElbow.position.x {
                let shoulderElbowAngleRange: ClosedRange<CGFloat> = 5 ... 25
                let leftShoulderElbowAngle = getShoulderElbowAngle(leftShoulder, leftElbow)
                let rightShoulderElbowAngle = getShoulderElbowAngle(rightShoulder, rightElbow)
                let shoulderElbowConditionSatisfiesd = shoulderElbowAngleRange.contains(leftShoulderElbowAngle) && shoulderElbowAngleRange.contains(rightShoulderElbowAngle)
                if shoulderElbowConditionSatisfiesd {
                    let elbowWristAngleRange: ClosedRange<CGFloat> = 70 ... 90
                    let leftElbowWristAngle = getElbowWristAngle(leftElbow, leftWrist)
                    let rightElbowWristAngle = getElbowWristAngle(rightElbow, rightWrist)
                    let elbowWristConditionSatisfiesd = elbowWristAngleRange.contains(leftElbowWristAngle) && elbowWristAngleRange.contains(rightElbowWristAngle)
                    retVal = elbowWristConditionSatisfiesd
                    if elbowWristConditionSatisfiesd {
                        retVal = abs(leftWrist.position.z - rightWrist.position.z) < 10
                    }
                }
            }
        }
        return retVal
    }
    
    private func getShoulderElbowAngle(_ shoulder: PoseLandmark, _ elbow: PoseLandmark) -> CGFloat {
        return getAngle(shoulder, secondPoint: elbow)
    }
    
    private func getElbowWristAngle(_ elbow: PoseLandmark, _ wrist: PoseLandmark) -> CGFloat {
        return getAngle(elbow, secondPoint: wrist)
    }
    
    private func getAngle(_ firstPoint: PoseLandmark, secondPoint: PoseLandmark) -> CGFloat {
        let y1 = firstPoint.position.y
        let y2 = secondPoint.position.y
        let x1 = firstPoint.position.x
        let x2 = secondPoint.position.x

        let alpha = atan2(abs(y2 - y1), abs(x2 - x1)) * 180 / CGFloat.pi
        return alpha
    }
    
    private func landmarksAreInFrame(_ leftElbow: PoseLandmark, _ rightElbow: PoseLandmark, _ leftWrist: PoseLandmark, _ rightWrist: PoseLandmark, _ leftShoulder: PoseLandmark, _ rightShoulder: PoseLandmark) -> Bool {
        let barrier: Float = 0.5
        return leftWrist.inFrameLikelihood > barrier && rightWrist.inFrameLikelihood > barrier && leftElbow.inFrameLikelihood > barrier && rightElbow.inFrameLikelihood > barrier && leftShoulder.inFrameLikelihood > barrier && rightWrist.inFrameLikelihood > barrier
    }
    
    private func setPoseDetector() {
        let options = AccuratePoseDetectorOptions()
        options.detectorMode = .stream
        poseDetector = PoseDetector.poseDetector(options: options)
    }
}
