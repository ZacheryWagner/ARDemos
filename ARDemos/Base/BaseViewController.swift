//
//  BaseViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/26/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import ARVideoKit

/**
 * Base view controller for AR Experiences handling the following
 * Recording: long press gesture, recording dot view, init, pause, and reset
 * ARConfiguration: init, pause, reset
 * Swipe to dismiss: gesture, functionality
 * - parameter realityConfiguration: Determines the `ARConfiguration`
 */
class BaseARViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate, UIGestureRecognizerDelegate, Recordable {
    /// Support ARConfigurations
    enum RealityConfiguration {
        case world, face
    }

    /// Sets the ARConfiguration
    var realityConfiguration: RealityConfiguration

    /// The scene for displaying content
    var sceneView = ARSCNView()

    /// For dismissing the view controller
    var edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: nil, action: nil)

    // MARK: - Recordable

    /// Handles recording
    var recorder: RecordAR?

    /// Getsure recognizer for handling starting/stopping recording
    var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)

    /// Dot indicating video is being recorded
    var recordingDot: UIView = UIView()

    /// Timer for `recordingDot` strobe animation
    var recordingStrobeTimer: Timer?

    /// Interval to strobe the live dot
    var recordingStrobeInterval: Double = 2.5

    /**
     * Initialize the AR view controller with a configuration for the AR experience
     */
    init(realityConfiguration: RealityConfiguration) {
        self.realityConfiguration = realityConfiguration

        super.init(nibName: nil, bundle: nil)

        recordingDot.isHidden = true
        recordingDot.backgroundColor = .red
        recordingDot.layer.cornerRadius = 6
        recordingDot.clipsToBounds = true

        // Setup dismiss gesture recognizer
        edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeFromEdge))
        edgeSwipeGestureRecognizer.edges = .left
        sceneView.addGestureRecognizer(edgeSwipeGestureRecognizer)

        // Setup record gesture recognizer
        longPressGestureRecognizer.addTarget(self, action: #selector(didLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 1.0
        sceneView.addGestureRecognizer(longPressGestureRecognizer)

        edgeSwipeGestureRecognizer.delegate = self
        longPressGestureRecognizer.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    /**
     * Initialize recorder
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the recorder
        recorder = RecordAR(ARSceneKit: sceneView)
    }

    /**
     * Reset tracking and disable screen dimming
     */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true

        // Reset to run the AR session for the first time.
        resetTracking()
    }

    /**
     * Pause the recorder and AR session
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        recorder?.rest()
        sceneView.session.pause()
    }

    /**
     * Dismiss the view controllers
     */
    @objc private func didSwipeFromEdge(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            navigationController?.popViewController(animated: true)
        }
    }

    /**
     * Reset the ARConfiguration specified and the recorder
     */
    func resetTracking() {
        guard ARWorldTrackingConfiguration.isSupported else { return }

        // Switch forces the implementation of new configurations
        switch realityConfiguration {
        case .world:
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.isLightEstimationEnabled = true

            recorder?.prepare(configuration)

            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        case .face:
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true

            recorder?.prepare(configuration)

            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    // MARK: - Recordable

    /**
     * Handles recording start/stop and recording dot show/stop
     */
    @objc private func didLongPress(_ recognizer: UILongPressGestureRecognizer) {
        AppUtils.checkCameraAndMicAccess(onAuthorized: {
            if recognizer.state == .began {
                self.recorder?.record()
                self.recordingDot.isHidden = false
                self.startRecordStrobe()
            } else if recognizer.state == .ended {
                AppUtils.checkPhotoAccess(onAuthorized: {
                    self.recorder?.stopAndExport()
                    self.recordingDot.isHidden = true
                    self.stopRecordStrobe()
                })
            }
        })
    }

    /**
     * Tick event for the timer strobe
     */
    @objc private func animateStrobe() {
        DispatchQueue.main.async {
            let halfDuration = self.recordingStrobeInterval / 2.0
            UIView.animate(withDuration: halfDuration, animations: {
                self.recordingDot.alpha = 0.1
            }) { _ in
                UIView.animate(withDuration: halfDuration, animations: {
                    self.recordingDot.alpha = 1
                })
            }
        }
    }

    /**
     * Start strobe animation
     */
    func startRecordStrobe() {
        guard recordingStrobeTimer == nil else { return }
        recordingStrobeTimer = Timer.scheduledTimer(timeInterval: recordingStrobeInterval, target: self, selector: #selector(animateStrobe), userInfo: nil, repeats: true)
    }

    /**
     * Stop strobe animation
     */
    func stopRecordStrobe() {
        guard recordingStrobeTimer != nil else { return }
        recordingStrobeTimer?.invalidate()
        recordingStrobeTimer = nil
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")

        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }

        resetTracking()

    }

    // MARK: - Error handling

    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - gestureRecognizer delegate

    /**
     *  Allow all gestures to happen simultaneously
     */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
