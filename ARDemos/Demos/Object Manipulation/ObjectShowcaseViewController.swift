//
//  ObjectShowcaseViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/19/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class ObjectShowcaseViewController: BaseARViewController, UITabBarDelegate {
    /// The anchor for the plane passed between content renderers
    var currentPlaneAnchor: ARPlaneAnchor?

    var planeNodes = [SCNNode]()

    var objectNode: SCNNode?

    /// The current angle of the object for panning
    var currentAngleY: Float = 0

    // MARK - Tabbable

    var tabBar = UITabBar()

    var contentControllers: [ObjectShowcaseTabTypes: ModelRenderer] = [:]

    /// Set in viewDidLoad initially and then changed with tab switching
    var selectedVirtualContent: ObjectShowcaseTabTypes! {
        didSet {
            guard oldValue != nil, oldValue != selectedVirtualContent
                else { return }

            // Remove existing content when switching types.
            contentControllers[oldValue]?.contentNode?.removeFromParentNode()
        }
    }

    /// Create the initial content or show the stored content
    var selectedContentController: VirtualContentRenderer {
        if let controller = contentControllers[selectedVirtualContent] {
            return controller
        } else {
            let controller = selectedVirtualContent.makeRenderer()
            contentControllers[selectedVirtualContent] = controller
            return controller
        }
    }

    init() {
        super.init(realityConfiguration: .world)

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        buildTabs()
        tabBar.barStyle = .black
        tabBar.isTranslucent = true
        tabBar.delegate = self

        recordingDot.isHidden = true
        recordingDot.backgroundColor = .red
        recordingDot.layer.cornerRadius = 6
        recordingDot.clipsToBounds = true

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)

        recordingDot.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordingDot)

        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBar)

        setupGestureRecognizers()
        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * Setup the object manipulation gestures
     */
    private func setupGestureRecognizers() {
        /// For adding objects on tap
        let sceneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapScene))

        /// For rotating the node
        let scenePanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanScene))

        /// For resizing the node
        let scenePinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinchScene))

        sceneView.addGestureRecognizer(sceneTapGestureRecognizer)
        sceneView.addGestureRecognizer(scenePanGestureRecognizer)
        sceneView.addGestureRecognizer(scenePinchGestureRecognizer)

        sceneTapGestureRecognizer.delegate = self
        scenePanGestureRecognizer.delegate = self
        scenePinchGestureRecognizer.delegate = self
    }

    /**
     * Build a tab for each model
     */
    private func buildTabs() {
        var tabBarItems: [UITabBarItem] = []
        tabBarItems.append(UITabBarItem(title: "Trophy", image: nil, tag: 0))
        tabBarItems.append(UITabBarItem(title: "Well", image: nil, tag: 1))

        tabBar.items = tabBarItems
    }

    private func initConstraints() {
        sceneView.pinToSuperviewTop()
        sceneView.pinToSuperviewLeading()
        sceneView.pinToSuperviewTrailing()
        sceneView.pinBottomToAnchor(tabBar.topAnchor)

        recordingDot.pinToSuperviewSafeAreaTop()
        recordingDot.pinToSuperviewLeadingWithInset(12)
        recordingDot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        recordingDot.heightAnchor.constraint(equalToConstant: 12).isActive = true

        tabBar.pinTopToAnchor(sceneView.bottomAnchor)
        tabBar.pinToSuperviewLeading()
        tabBar.pinToSuperviewTrailing()
        tabBar.pinToSuperviewSafeAreaBottom()
    }

    /**
     * Place an object at the location and remove the object of it exists
     */
    @objc private func didTapScene(_ recognizer: UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView,
            let anchor = currentPlaneAnchor,
            let node = sceneView.node(for: anchor)
            else { return }

        let touchLocation = recognizer.location(in: sceneView)

        // Ensure tap location exists
        if let result = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent).first {
            if let newContent = selectedContentController.renderer(sceneView, nodeFor: anchor) {
                //let objectHeight = newContent.boundingBox.max.y - newContent.boundingBox.min.y

                // Get position in 3D Space and convert that to a 3 Coordinate vector
                let position = result.worldTransform.columns.3
                let float = float3(x: position.x, y: position.y, z: position.z)
                let vector = SCNVector3Make(float.x, float.y + 0.1, float.z)

                objectNode = newContent
                objectNode!.position = vector

                if node.childNodes.count > planeNodes.count {
                    node.replaceChildNode(
                        node.childNodes[node.childNodes.count - 1],
                        with: objectNode!
                    )
                } else {
                    node.addChildNode(objectNode!)
                }
            }
        }
    }

    /**
     * Rotate the node
     */
    @objc private func didPanScene(recognizer: UIPanGestureRecognizer) {
        guard let objectNode = objectNode else { return }

        let translation = recognizer.translation(in: recognizer.view)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0

        newAngleY += currentAngleY
        objectNode.eulerAngles.y = newAngleY

        if recognizer.state == .ended {
            currentAngleY = newAngleY
        }
    }

    /**
     * Resize the node to scale with pinch gesture
     */
    @objc func didPinchScene(_ gesture: UIPinchGestureRecognizer) {
        guard let objectNode = objectNode else { return }

        var originalScale = objectNode.scale

        switch gesture.state {
        case .began:
            originalScale = objectNode.scale
            gesture.scale = CGFloat(objectNode.scale.x)
        case .changed:
            var newScale = originalScale
            if gesture.scale < 0.5 {
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            } else if gesture.scale > 2 {
                newScale = SCNVector3(2, 2, 2)
            } else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }

            objectNode.scale = newScale
        case .ended:
            var newScale = originalScale
            if gesture.scale < 0.5 {
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            } else if gesture.scale > 2 {
                newScale = SCNVector3(2, 2, 2)
            } else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }

            objectNode.scale = newScale
            gesture.scale = CGFloat(objectNode.scale.x)
        default:
            gesture.scale = 1.0
        }
    }

    // MARK: - ARSCNViewDelegate

    /**
     * Set the plane anchor and add plane nodes
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        currentPlaneAnchor = planeAnchor

        // Create the the plane
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0)

        let planeNode = SCNNode(geometry: plane)

        // Set position of the plane
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)

        // Make the plane parallel to the floor
        planeNode.eulerAngles.x = -.pi / 2

        node.addChildNode(planeNode)

        planeNodes.append(planeNode)
    }

    /**
     * Remove plane nodes
     */
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor,
            let planeNode = node.childNodes.first
            else { return }
        planeNodes = planeNodes.filter { $0 != planeNode }
    }

    /**
     * Update plane nodes
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
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
    }

    /// MARK - Tabbable (UITabBarDelegate)

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let contentType = ObjectShowcaseTabTypes(rawValue: item.tag)
            else { fatalError("unexpected virtual content tag") }
        selectedVirtualContent = contentType
    }
}


