//
//  SingleObjectManipulationViewController.swift
//  ARObjectRendering
//
//  Created by Zachery Wagner on 7/16/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class SingleObjectManipulationViewController: UIViewController, ARSCNViewDelegate {
    var sceneView = ARSCNView()

    /// Node for the scene
    var mainNode: SCNNode

    /// Cube for the ndoe
    var box: SCNBox

    /// Display updated info on the surface tracking
    var infoLabel = UILabel()

    /// Toggles whether or not scene kit is lit
    var toggleLightingButton = UILabel()

    var viewModel: SingleObjectManipulationViewModel

    init(viewModel: SingleObjectManipulationViewModel) {
        self.viewModel = viewModel

        box = SCNBox(width: viewModel.boxDimension, height: viewModel.boxDimension, length: viewModel.boxDimension, chamferRadius: 0)

        mainNode = SCNNode(geometry: box)

        super.init(nibName: nil, bundle: nil)

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Setup Gesture recognizers
        let sceneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleMaterials))
        sceneView.addGestureRecognizer(sceneTapGestureRecognizer)

        let lightingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleLighting))
        toggleLightingButton.addGestureRecognizer(lightingTapGestureRecognizer)

//        let pinchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(resizeNode))
//        sceneView.addGestureRecognizer(pinchGestureRecognizer)

        // Setup label
        infoLabel.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        infoLabel.lineBreakMode = .byWordWrapping

        // Setup buttons
        toggleLightingButton.text = viewModel.lightingButtonText
        toggleLightingButton.backgroundColor = viewModel.buttonColor
        toggleLightingButton.isUserInteractionEnabled = true

        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLightingForState(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create and run a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    private func initConstraints() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        sceneView.pinToSuperview()

        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoLabel)
        infoLabel.pinToSuperviewSafeAreaTop()
        infoLabel.pinToSuperviewCenterX()

        toggleLightingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleLightingButton)
        toggleLightingButton.pinToSuperviewSafeAreaBottomWithInset(24)
        toggleLightingButton.pinToSuperviewSafeAreaTrailingWithInset(12)
    }


    /**
     * Resize the node to scale with pinch gesture
     */
    @objc func resizeNode(_ gesture: UIPinchGestureRecognizer) {
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
            }else if gesture.scale > 2 {
                newScale = SCNVector3(2, 2, 2)
            }else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }

            mainNode.scale = newScale
            gesture.scale = CGFloat(mainNode.scale.x)
        default:
            gesture.scale = 1.0
        }
    }

    /**
     * Set the nodes materials
     */
    @objc private func toggleMaterials(recognizer: UITapGestureRecognizer) {
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])

        // If the node has been touched
        if !hitResults.isEmpty {
            guard let hitResult = hitResults.first else { return }

            viewModel.incrimentTextureIndex()

            let node = hitResult.node
            node.geometry?.materials = viewModel.getTextureForCurrentIndex()
        }
    }

    @objc private func toggleLighting() {
        viewModel.isLightingActive.toggle()
        toggleLightingButton.text = viewModel.lightingButtonText
        configureLightingForState(viewModel.isLightingActive)
    }

    /**
     * Set the scenes lighting to active or inactive
     */
    private func configureLightingForState(_ isActive: Bool) {
        sceneView.autoenablesDefaultLighting = isActive
        sceneView.automaticallyUpdatesLighting = isActive
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
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
