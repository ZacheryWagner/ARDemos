//
//  ObjectManipulationViewController.swift
//  ARObjectRendering
//
//  Created by Zachery Wagner on 7/16/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit
import ARVideoKit

class ObjectManipulationViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate, Recordable {
    var sceneView = ARSCNView()

    // MARK: - Recordable

    var recorder: RecordAR?

    var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)

    var recordingDot: UIView = UIView()

    var recordingStrobeTimer: Timer?

    var recordingStrobeInterval: Double = 2.5

    /// Node for the scene
    var mainNode: SCNNode

    /// Cube for the node
    var box: SCNBox

    /// Display updated info on the surface tracking
    var infoLabel = UILabel()

    /// Toggles whether or not scene kit is lit
    var toggleLightingButton = UILabel()

    /// Toggles sceneView.debugOptoins
    var toggleDebugButton = UILabel()

    /// Vertical stack of buttons
    var buttonStackView = UIStackView()

    /// For swapping textures and moving the node to the tap location
    var sceneTapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)

    /// For rotating the node
    var scenePanGestureRecognizer = UIPanGestureRecognizer(target: nil, action: nil)

    /// For resizing the node
    var scenePinchGestureRecognizer = UIPinchGestureRecognizer(target: nil, action: nil)

    /// For dismissing the view controller
    var edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: nil, action: nil)

    private var viewModel: ObjectManipulationViewModel

    init(viewModel: ObjectManipulationViewModel) {
        self.viewModel = viewModel

        box = SCNBox(
            width: viewModel.boxDimension,
            height: viewModel.boxDimension,
            length: viewModel.boxDimension,
            chamferRadius: 0)
        mainNode = SCNNode(geometry: box)

        longPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)

        super.init(nibName: nil, bundle: nil)

        sceneView.delegate = self
        sceneView.showsStatistics = true

        // Setup label
        infoLabel.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        infoLabel.lineBreakMode = .byWordWrapping

        // Setup buttons
        toggleLightingButton.text = viewModel.lightingButtonText
        toggleLightingButton.backgroundColor = viewModel.buttonColor
        toggleLightingButton.isUserInteractionEnabled = true

        toggleDebugButton.text = viewModel.debugButtonText
        toggleDebugButton.backgroundColor = viewModel.buttonColor
        toggleDebugButton.isUserInteractionEnabled = true

        // Setup views
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        recordingDot.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(sceneView)
        view.addSubview(infoLabel)
        view.addSubview(buttonStackView)
        view.addSubview(recordingDot)

        recordingDot.isHidden = true
        recordingDot.backgroundColor = .red
        recordingDot.layer.cornerRadius = 6
        recordingDot.clipsToBounds = true

        buttonStackView.axis = .vertical
        buttonStackView.spacing = 12

        buttonStackView.addArrangedSubview(toggleLightingButton)
        buttonStackView.addArrangedSubview(toggleDebugButton)

        // Additionally setup
        configureLightingForState(true)
        setupGestureRecognizer()
        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the recorder
        recorder = RecordAR(ARSceneKit: sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create the session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Prepare the recorder
        recorder?.prepare(configuration)

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        recorder?.rest()
        sceneView.session.pause()
    }

    private func setupGestureRecognizer() {
        longPressGestureRecognizer.addTarget(self, action: #selector(didLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 1.0
        sceneView.addGestureRecognizer(longPressGestureRecognizer)

        sceneTapGestureRecognizer.addTarget(self, action: #selector(didTapScene))
        sceneView.addGestureRecognizer(sceneTapGestureRecognizer)

        scenePanGestureRecognizer.addTarget(self, action: #selector(didPanScene))
        sceneView.addGestureRecognizer(scenePanGestureRecognizer)

        scenePinchGestureRecognizer.addTarget(self, action: #selector(didPinchScene))
        sceneView.addGestureRecognizer(scenePinchGestureRecognizer)

        edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeFromEdge))
        edgeSwipeGestureRecognizer.edges = .left
        sceneView.addGestureRecognizer(edgeSwipeGestureRecognizer)

        longPressGestureRecognizer.delegate = self
        sceneTapGestureRecognizer.delegate = self
        scenePanGestureRecognizer.delegate = self
        scenePinchGestureRecognizer.delegate = self
        edgeSwipeGestureRecognizer.delegate = self

        let lightingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleLighting))
        toggleLightingButton.addGestureRecognizer(lightingTapGestureRecognizer)

        let debugTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleDebug))
        toggleDebugButton.addGestureRecognizer(debugTapGestureRecognizer)
    }

    private func initConstraints() {
        sceneView.pinToSuperview()

        infoLabel.pinToSuperviewSafeAreaTop()
        infoLabel.pinToSuperviewCenterX()

        recordingDot.pinToSuperviewSafeAreaTop()
        recordingDot.pinToSuperviewLeadingWithInset(12)
        recordingDot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        recordingDot.heightAnchor.constraint(equalToConstant: 12).isActive = true

        buttonStackView.pinToSuperviewSafeAreaBottomWithInset(24)
        buttonStackView.pinToSuperviewSafeAreaTrailingWithInset(12)
    }

    /**
     * Set the nodes materials
     */
    @objc private func didTapScene(recognizer: UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else { return }

        let touchLocation = recognizer.location(in: sceneView)

        // If tapped node, else if tapped space
        if let result = sceneView.hitTest(touchLocation, options: [:]).first {
            viewModel.incrimentTextureIndex()

            let node = result.node
            node.geometry?.materials = viewModel.getTextureForCurrentIndex()
        } else if let result = sceneView.hitTest(touchLocation, types: .featurePoint).first {
            // Get position in 3D Space and convert that to a 3 Coordinate vector
            let position = result.worldTransform.columns.3
            let float = float3(x: position.x, y: position.y, z: position.z)
            let vector = SCNVector3Make(float.x, float.y, float.z)

            mainNode.removeFromParentNode()
            mainNode.position = vector
            sceneView.scene.rootNode.addChildNode(mainNode)
        }
    }

    /**
     * Rotate the node
     */
    @objc private func didPanScene(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0

        newAngleY += viewModel.currentAngleY
        mainNode.eulerAngles.y = newAngleY

        if recognizer.state == .ended {
            viewModel.currentAngleY = newAngleY
        }
    }

    /**
     * Resize the node to scale with pinch gesture
     */
    @objc func didPinchScene(_ gesture: UIPinchGestureRecognizer) {
        var originalScale = mainNode.scale

        switch gesture.state {
        case .began:
            originalScale = mainNode.scale
            gesture.scale = CGFloat(mainNode.scale.x)
        case .changed:
            var newScale = originalScale
            if gesture.scale < 0.5 {
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            } else if gesture.scale > 2 {
                    newScale = SCNVector3(2, 2, 2)
            } else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }

            mainNode.scale = newScale
        case .ended:
            var newScale = originalScale
            if gesture.scale < 0.5 {
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            } else if gesture.scale > 2 {
                newScale = SCNVector3(2, 2, 2)
            } else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }

            mainNode.scale = newScale
            gesture.scale = CGFloat(mainNode.scale.x)
        default:
            gesture.scale = 1.0
        }
    }

    @objc private func didSwipeFromEdge(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func toggleLighting() {
        viewModel.isLightingActive.toggle()
        toggleLightingButton.text = viewModel.lightingButtonText
        configureLightingForState(viewModel.isLightingActive)
    }

    @objc private func toggleDebug() {
        viewModel.isDebugActive.toggle()
        toggleDebugButton.text = viewModel.debugButtonText

        if sceneView.debugOptions == [] {
            sceneView.debugOptions = [.showFeaturePoints, .showBoundingBoxes]
        } else {
            sceneView.debugOptions = []
        }
    }

    /**
     * Set the scenes lighting to active or inactive
     */
    private func configureLightingForState(_ isActive: Bool) {
        sceneView.autoenablesDefaultLighting = isActive
        sceneView.automaticallyUpdatesLighting = isActive
    }

    // MARK: - Recordable

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

    func startRecordStrobe() {
        guard recordingStrobeTimer == nil else { return }
        recordingStrobeTimer = Timer.scheduledTimer(timeInterval: recordingStrobeInterval, target: self, selector: #selector(animateStrobe), userInfo: nil, repeats: true)
    }

    func stopRecordStrobe() {
        guard recordingStrobeTimer != nil else { return }
        recordingStrobeTimer?.invalidate()
        recordingStrobeTimer = nil
    }

    // MARK: - gestureRecognizer delegate

    /**
     *  Allow all gestures to happen simultaneously
     */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
    }

    // MARK: - ARSCNView delegate

    /**
     * Called when any node has been added to the anchor
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        DispatchQueue.main.async {
            self.infoLabel.text = "Surface Detected."
        }

        mainNode.simdPosition = float3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        sceneView.scene.rootNode.addChildNode(mainNode)
        node.addChildNode(mainNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // This method will help when any node has been removed from sceneview
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Called when any node has been updated with data from anchor
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // help us inform the user when the app is ready
        switch camera.trackingState {
        case .normal :
            infoLabel.text = "Move the device to detect horizontal surfaces."

        case .notAvailable:
            infoLabel.text = "Tracking not available."

        case .limited(.excessiveMotion):
            infoLabel.text = "Move the device more slowly."

        case .limited(.insufficientFeatures):
            infoLabel.text = "Point the device at an area with visible surface detail."

        case .limited(.initializing):
            infoLabel.text = "Initializing AR session."

        default:
            infoLabel.text = ""
        }
    }

    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        infoLabel.text = "Session was interrupted"
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        infoLabel.text = "Session interruption ended"
        resetTracking()
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        infoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }

    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        recorder?.prepare(configuration)

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
