//
//  StickerViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/29/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class StickerViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    /// The scene for display
    var sceneView = ARSCNView()

    // The node with the face and the sticker
    var contentNode = SCNNode()

    /// The node with the face geometry
    var occlusionNode = SCNNode()

    // THe node for the sticker
    var stickerNode: SCNNode?

    var currentFaceAnchor: ARFaceAnchor?

    /// For dismissing the view controller
    var edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: nil, action: nil)

    init() {
        super.init(nibName: nil, bundle: nil)

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        edgeSwipeGestureRecognizer.addTarget(self, action: #selector(didSwipeFromEdge))
        edgeSwipeGestureRecognizer.edges = .left
        sceneView.addGestureRecognizer(edgeSwipeGestureRecognizer)

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)

        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true

        // "Reset" to run the AR session for the first time.
        resetTracking()
    }

    private func initConstraints() {
        sceneView.pinToSuperview()
    }

    @objc private func didSwipeFromEdge(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - ARSCNViewDelegate

    /**
     * Called when any node has been added to the anchor
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let device = sceneView.device
            else { return }

        currentFaceAnchor = faceAnchor

        /*
         Write depth but not color and render before other objects.
         This causes the geometry to occlude other SceneKit content
         while showing the camera view beneath, creating the illusion
         that real-world objects are obscuring virtual 3D objects.
         */
        let faceGeometry = ARSCNFaceGeometry(device: device)!
        faceGeometry.firstMaterial!.colorBufferWriteMask = []
        occlusionNode = SCNNode(geometry: faceGeometry)
        occlusionNode.renderingOrder = -1

        // Add the occlusion node to the scene
        contentNode = SCNNode()
        contentNode.addChildNode(occlusionNode)
        node.addChildNode(contentNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = occlusionNode.geometry as? ARSCNFaceGeometry,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }

        faceGeometry.update(from: faceAnchor.geometry)
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

    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
