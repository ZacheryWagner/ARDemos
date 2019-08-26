//
//  ObjectStickerViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/29/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class ObjectStickerViewController: BaseARViewController {
    // Holds the node with the face and specific face renderers
    var texturedFaceRenderer: FaceRenderer?

    // Passed to render the face
    var currentFaceAnchor: ARFaceAnchor?

    // Node with the face and sticker
    var contentNode: SCNNode?

    // Node with just the sticker
    var stickerNode: SCNReferenceNode?

    init() {
        super.init(realityConfiguration: .face)

        texturedFaceRenderer = FaceRenderer()

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        // Setup tap gesture
        let sceneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapScene))
        sceneView.addGestureRecognizer(sceneTapGestureRecognizer)

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)

        recordingDot.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordingDot)

        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initConstraints() {
        sceneView.pinToSuperview()

        recordingDot.pinToSuperviewSafeAreaTop()
        recordingDot.pinToSuperviewLeadingWithInset(12)
        recordingDot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        recordingDot.heightAnchor.constraint(equalToConstant: 12).isActive = true
    }

    /**
     * Attach sticker object to tap location with propper angle and position
     */
    @objc private func didTapScene(recognizer: UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView,
            let contentNode = contentNode
            else { return }

        let touchLocation = recognizer.location(in: sceneView)

        // If tapped face
        if let result = sceneView.hitTest(touchLocation, options: [:]).first {
            stickerNode = SCNReferenceNode(named: "letterD")

            guard let stickerNode = stickerNode else { return }

            // An estimation of the nose
            let nosePoint = SCNVector3(0, 0, 0.7)

            // Get the angle of the sticker to match the facial feature
            var theta = MathUtils.getAngleBetweenTwo3DPoints(
                pointA: nosePoint,
                pointB: result.localCoordinates
                )

            // Account for negative values of a graphing coordiantes
            if result.localCoordinates.x < 0 {
                theta.negate()
            }

            // This stop any awkward face geometry from yielding unexpected result
            if abs(theta) < 80 {
                stickerNode.eulerAngles.y = theta.toRadians()

            }

//            // The length of the object that has now been push behind the face
//            let distanceRotated = ((nosePoint.z + result.localCoordinates.z) / 2) - result.localCoordinates.z
//            print("Point B: ", result.localCoordinates.z)
//            print("Point C: ", (nosePoint.z + result.localCoordinates.z) / 2)
//            print("Distance Rotated: ", distanceRotated)

            stickerNode.position = result.localCoordinates
            //stickerNode.position.z = result.localCoordinates.z + distanceRotated

            contentNode.addChildNode(stickerNode)
        }
    }

    // MARK: - ARSCNViewDelegate

    /**
     * Called when any node has been added to the anchor
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let texturedFaceNode = texturedFaceRenderer
            else { return }

        currentFaceAnchor = faceAnchor

        if let faceNode = texturedFaceNode.renderer(renderer, nodeFor: faceAnchor) {
            contentNode = SCNNode()
            contentNode?.addChildNode(faceNode)

            sceneView.scene.rootNode.addChildNode(contentNode!)
            node.addChildNode(contentNode!)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor == currentFaceAnchor,
            let texturedFaceRenderer = texturedFaceRenderer,
            let contentNode = texturedFaceRenderer.contentNode,
            contentNode.parent == node
            else { return }

        texturedFaceRenderer.renderer(renderer, didUpdate: contentNode, for: anchor)
    }
}
