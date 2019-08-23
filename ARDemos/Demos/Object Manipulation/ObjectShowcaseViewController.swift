//
//  ObjectShowcaseViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/19/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import ARVideoKit

class ObjectShowcaseViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate, UIGestureRecognizerDelegate, Recordable {
    var sceneView = ARSCNView()

    /// The current angle of the object for panning
    var currentAngleY: Float = 0

    /// For rotating the node
    var scenePanGestureRecognizer = UIPanGestureRecognizer(target: nil, action: nil)

    /// For resizing the node
    var scenePinchGestureRecognizer = UIPinchGestureRecognizer(target: nil, action: nil)

    /// For adding objects on tap
    var sceneTapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)

    /// For dismissing the view controller
    var edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: nil, action: nil)

    // MARK: - Recordable

    var recorder: RecordAR?

    var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)

    var recordingDot: UIView = UIView()

    var recordingStrobeTimer: Timer?

    var recordingStrobeInterval: Double = 2.5

    var tabBar = UITabBar()

    // - MARK: Rendering Properties

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

    /// Tied to the object
    var currentPlaneAnchor: ARPlaneAnchor?
    var planeNodes = [SCNNode]()

    var objectNode: SCNNode?

    init() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)

        super.init(nibName: nil, bundle: nil)

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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the initial tab
        tabBar.selectedItem = tabBar.items!.first!
        selectedVirtualContent = ObjectShowcaseTabTypes(rawValue: tabBar.selectedItem!.tag)

        // Initialize the recorder
        recorder = RecordAR(ARSceneKit: sceneView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true

        // "Reset" to run the AR session for the first time.
        resetTracking()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        recorder?.rest()
        sceneView.session.pause()
    }

    private func setupGestureRecognizers() {
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
    }

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

    @objc private func didTapScene(_ recognizer: UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView,
            let anchor = currentPlaneAnchor,
            let node = sceneView.node(for: anchor)
            else { return }

        let touchLocation = recognizer.location(in: sceneView)

        // Ensure tap location exists
        if let result = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent).first {
            if let newContent = selectedContentController.renderer(sceneView, nodeFor: anchor) {
                let objectHeight = newContent.boundingBox.max.y - newContent.boundingBox.min.y

                // Get position in 3D Space and convert that to a 3 Coordinate vector
                let position = result.worldTransform.columns.3
                let float = float3(x: position.x, y: position.y + objectHeight, z: position.z)
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

    @objc private func didSwipeFromEdge(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            navigationController?.popViewController(animated: true)
        }
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

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        currentPlaneAnchor = planeAnchor

        // Create the the plane
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.3)

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

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor,
            let planeNode = node.childNodes.first
            else { return }
        planeNodes = planeNodes.filter { $0 != planeNode }
    }

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

    // MARK: - gestureRecognizer delegate

    /**
     *  Allow all gestures to happen simultaneously
     */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func resetTracking() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        recorder?.prepare(configuration)

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ObjectShowcaseViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let contentType = ObjectShowcaseTabTypes(rawValue: item.tag)
            else { fatalError("unexpected virtual content tag") }
        selectedVirtualContent = contentType
    }
}


