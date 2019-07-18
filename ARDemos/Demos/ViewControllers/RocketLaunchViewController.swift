//
//  RocketLaunchViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/18/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import ARKit

class RocketLaunchViewController: UIViewController, ARSCNViewDelegate {
    private var sceneView = ARSCNView()

    private var planeNodes = [SCNNode]()

    private var viewModel: RocketLaunchViewModel

    init(viewModel: RocketLaunchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        sceneView.delegate = self

        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        sceneView.pinToSuperviewSafeArea()

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
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeDownScene))
        let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeUpScene))

        swipeDownGestureRecognizer.direction = .down
        swipeUpGestureRecognizer.direction = .up

        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.addGestureRecognizer(swipeDownGestureRecognizer)
        sceneView.addGestureRecognizer(swipeUpGestureRecognizer)
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
        guard let rocketshipScene = SCNScene(named: "rocketship.scn"), let rocketshipNode = rocketshipScene.rootNode.childNode(withName: "rocketship", recursively: false)
            else { return }

        // Get position in 3D Space and convert that to a 3 Coordinate vector
        let position = result.worldTransform.columns.3
        let float = float3(x: position.x, y: position.y, z: position.z)
        let vector = SCNVector3Make(float.x, float.y + 0.1, float.z)

        rocketshipNode.position = vector

        // Attach physics body to rocketship node
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        rocketshipNode.physicsBody = physicsBody
        rocketshipNode.name = viewModel.rocketshipNodeName

        sceneView.scene.rootNode.addChildNode(rocketshipNode)

    }

    /**
     * Apply the force to the rocketship
     */
    @objc private func didSwipeDownScene(_ recognizer: UISwipeGestureRecognizer) {
        guard recognizer.state == .ended else { return }

        let swipeLocation = recognizer.location(in: sceneView)
        guard let rocketshipNode = getRocketshipNode(from: swipeLocation),
            let physicsBody = rocketshipNode.physicsBody
            else { return }

        let direction = SCNVector3(0, 3, 0)
        physicsBody.applyForce(direction, asImpulse: true)
    }

    /**
     * Launch the rocketship
     */
    @objc private func didSwipeUpScene(_ recognizer: UISwipeGestureRecognizer) {
        guard recognizer.state == .ended else { return }

        // Set particles to engine of the rocketship
        let swipeLocation = recognizer.location(in: sceneView)
        guard let rocketshipNode = getRocketshipNode(from: swipeLocation),
            let physicsBody = rocketshipNode.physicsBody,
            let reactorParticleSystem = SCNParticleSystem(named: "reactor", inDirectory: nil),
            let engineNode = rocketshipNode.childNode(withName: "node2", recursively: false)
            else { return }

        physicsBody.isAffectedByGravity = false
        physicsBody.damping = 0

        // Make the particles collide with the plane
        reactorParticleSystem.colliderNodes = planeNodes

        engineNode.addParticleSystem(reactorParticleSystem)

        // Launch
        let action = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 3)
        action.timingMode = .easeInEaseOut
        rocketshipNode.runAction(action)
    }

    func getRocketshipNode(from swipeLocation: CGPoint) -> SCNNode? {
        let hitTestResults = sceneView.hitTest(swipeLocation)
        guard let parentNode = hitTestResults.first?.node.parent,
            parentNode.name == viewModel.rocketshipNodeName
            else { return nil }

        return parentNode
    }

    // MARK: - ARSCNView delegate

    /**
     * Update the plane geometry, physics, position, and pitch
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Get the plane and make it visable
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.7)

        var planeNode = SCNNode(geometry: plane)

        // Set position and pitch
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
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
