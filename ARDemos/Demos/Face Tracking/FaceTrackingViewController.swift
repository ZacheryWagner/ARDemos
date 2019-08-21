//
//  FaceTrackingViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/19/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import ARVideoKit

class FaceTrackingViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate, Recordable {
    var sceneView = ARSCNView()

    // MARK: - Recordable

    var recorder: RecordAR?

    var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)

    var recordingDot: UIView = UIView()

    var recordingStrobeTimer: Timer?

    var recordingStrobeInterval: Double = 2.5

    var tabBar = UITabBar()

    var contentControllers: [FaceTrackingTabTypes: VirtualContentRenderer] = [:]

    /// For dismissing the view controller
    var edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: nil, action: nil)

    var selectedVirtualContent: FaceTrackingTabTypes! {
        didSet {
            guard oldValue != nil, oldValue != selectedVirtualContent
                else { return }

            // Remove existing content when switching types.
            contentControllers[oldValue]?.contentNode?.removeFromParentNode()

            // If there's an anchor already (switching content), get the content controller to place initial content.
            // Otherwise, the content controller will place it in `renderer(_:didAdd:for:)`.
            if let anchor = currentFaceAnchor, let node = sceneView.node(for: anchor),
                let newContent = selectedContentController.renderer(sceneView, nodeFor: anchor) {
                node.addChildNode(newContent)
            }
        }
    }

    var selectedContentController: VirtualContentRenderer {
        if let controller = contentControllers[selectedVirtualContent] {
            return controller
        } else {
            let controller = selectedVirtualContent.makeRenderer()
            contentControllers[selectedVirtualContent] = controller
            return controller
        }
    }

    var currentFaceAnchor: ARFaceAnchor?

    init() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: nil, action: nil)

        super.init(nibName: nil, bundle: nil)

        buildTabs()
        tabBar.barStyle = .black
        tabBar.isTranslucent = true
        tabBar.delegate = self

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        edgeSwipeGestureRecognizer.addTarget(self, action: #selector(didSwipeFromEdge))
        edgeSwipeGestureRecognizer.edges = .left
        sceneView.addGestureRecognizer(edgeSwipeGestureRecognizer)

        longPressGestureRecognizer.addTarget(self, action: #selector(didLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 1.0
        sceneView.addGestureRecognizer(longPressGestureRecognizer)

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)

        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBar)

        recordingDot.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordingDot)

        recordingDot.isHidden = true
        recordingDot.backgroundColor = .red
        recordingDot.layer.cornerRadius = 6
        recordingDot.clipsToBounds = true

        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the initial tab
        tabBar.selectedItem = tabBar.items!.first!
        selectedVirtualContent = FaceTrackingTabTypes(rawValue: tabBar.selectedItem!.tag)
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

    private func buildTabs() {
        var tabBarItems: [UITabBarItem] = []
        tabBarItems.append(UITabBarItem(title: "Transform", image: UIImage(named: "transforms"), tag: 0))
        tabBarItems.append(UITabBarItem(title: "Texture", image: UIImage(named: "texture"), tag: 1))
        tabBarItems.append(UITabBarItem(title: "3D Overlay", image: UIImage(named: "geometry"), tag: 2))
        tabBarItems.append(UITabBarItem(title: "Video Texture", image: UIImage(named: "videoTexture"), tag: 3))
        tabBarItems.append(UITabBarItem(title: "Blend Shapes", image: UIImage(named: "blendShapes"), tag: 4))

        tabBar.items = tabBarItems
    }

    private func initConstraints() {
        sceneView.pinToSuperviewTop()
        sceneView.pinToSuperviewLeading()
        sceneView.pinToSuperviewTrailing()
        sceneView.pinBottomToAnchor(tabBar.topAnchor)

        tabBar.pinTopToAnchor(sceneView.bottomAnchor)
        tabBar.pinToSuperviewLeading()
        tabBar.pinToSuperviewTrailing()
        tabBar.pinToSuperviewSafeAreaBottom()

        recordingDot.pinToSuperviewSafeAreaTop()
        recordingDot.pinToSuperviewLeadingWithInset(12)
        recordingDot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        recordingDot.heightAnchor.constraint(equalToConstant: 12).isActive = true
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
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor

        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        if node.childNodes.isEmpty, let contentNode = selectedContentController.renderer(renderer, nodeFor: faceAnchor) {
            node.addChildNode(contentNode)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor == currentFaceAnchor,
            let contentNode = selectedContentController.contentNode,
            contentNode.parent == node
            else { return }

        selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
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

        recorder?.prepare(configuration)

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

}

extension FaceTrackingViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let contentType = FaceTrackingTabTypes(rawValue: item.tag)
            else { fatalError("unexpected virtual content tag") }
        selectedVirtualContent = contentType
    }
}
