//
//  FaceTextureViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/12/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class FaceTextureViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    var sceneView = ARSCNView()

    var tabBar = UITabBar()

    var contentControllers: [FaceTextureTabTypes: FaceRenderer] = [:]

    /// For dismissing the view controller
    var edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: nil, action: nil)

    var selectedVirtualContent: FaceTextureTabTypes! {
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
        super.init(nibName: nil, bundle: nil)

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        buildTabs()
        tabBar.barStyle = .black
        tabBar.isTranslucent = true
        tabBar.delegate = self

        edgeSwipeGestureRecognizer.addTarget(self, action: #selector(didSwipeFromEdge))
        edgeSwipeGestureRecognizer.edges = .left
        sceneView.addGestureRecognizer(edgeSwipeGestureRecognizer)

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)

        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBar)

        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the initial tab
        tabBar.selectedItem = tabBar.items!.first!
        selectedVirtualContent = FaceTextureTabTypes(rawValue: tabBar.selectedItem!.tag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true

        // "Reset" to run the AR session for the first time.
        resetTracking()
    }

    private func buildTabs() {
        var tabBarItems: [UITabBarItem] = []
        tabBarItems.append(UITabBarItem(title: "Drund", image: nil, tag: 0))
        tabBarItems.append(UITabBarItem(title: "Zach", image: nil, tag: 1))
        tabBarItems.append(UITabBarItem(title: "Clown", image: nil, tag: 2))

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
    }

    @objc private func didSwipeFromEdge(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            navigationController?.popViewController(animated: true)
        }
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
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

}

extension FaceTextureViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let contentType = FaceTextureTabTypes(rawValue: item.tag)
            else { fatalError("unexpected virtual content tag") }
        selectedVirtualContent = contentType
    }
}

