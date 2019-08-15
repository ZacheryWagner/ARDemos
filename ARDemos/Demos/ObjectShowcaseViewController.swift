//
//  ObjectShowcaseViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/14/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

class ObjectShowcaseViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate {
    private var sceneView = ARSCNView()

    private var planeNodes = [SCNNode]()

    init() {
        super.init(nibName: nil, bundle: nil)

        sceneView.delegate = self

        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        sceneView.pinToSuperview()

        setupGestureRecognizers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    private func setupGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapScene))
        let edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(didSwipeFromEdge))

        edgeSwipeGestureRecognizer.edges = .left

        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.addGestureRecognizer(edgeSwipeGestureRecognizer)
    }

    /**
     * Add the rocket ship to the scene
     */
    @objc private func didTapScene(_ recognizer: UITapGestureRecognizer) {
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = recognizer.location(in: sceneView)

        // Ensure tap location exists
        guard let result = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent).first else { return }

        // Build the rocketship model
        guard let trophyScene = SCNScene(named: "swell.scn") else { return }

        let trophyNode = trophyScene.rootNode

        // Get position in 3D Space and convert that to a 3 Coordinate vector
        let position = result.worldTransform.columns.3
        let float = float3(x: position.x, y: position.y, z: position.z)
        let vector = SCNVector3Make(float.x, float.y + 0.1, float.z)

        trophyNode.position = vector

        sceneView.scene.rootNode.addChildNode(trophyNode)
    }

    @objc private func didSwipeFromEdge(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - ARSCNView delegate

    /**
     * Set the plane geometry, physics, position, and pitch
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Create the the plane
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.3)

        var planeNode = SCNNode(geometry: plane)

        // Set position of the plane
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)

        // Make the plane parallel to the floor (flat)
        planeNode.eulerAngles.x = -.pi / 2

        applyGeometryAndPhysicsToNode(&planeNode, withGeometry: plane, physicsType: .static)

        node.addChildNode(planeNode)

        planeNodes.append(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor,
            let planeNode = node.childNodes.first
            else { return }
        planeNodes = planeNodes.filter { $0 != planeNode }
    }

    /**
     * Update the plane geometry, physics, and position
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            var planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)

        planeNode.position = SCNVector3(x, y, z)

        applyGeometryAndPhysicsToNode(&planeNode, withGeometry: plane, physicsType: .static)
    }

    /**
     * Set `geometry` to `node` with `physicsType`
     */
    func applyGeometryAndPhysicsToNode(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, physicsType: SCNPhysicsBodyType) {
        let shape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: physicsType, shape: shape)
        node.physicsBody = physicsBody
    }
}
