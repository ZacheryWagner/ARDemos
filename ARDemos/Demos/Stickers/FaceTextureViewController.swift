//
//  FaceTextureViewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/12/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class FaceTextureViewController: BaseARViewController, UITabBarDelegate {
    // The anchor for the face passed between content renderers
    var currentFaceAnchor: ARFaceAnchor?

    // MARK - Tabbable

    var tabBar: UITabBar = UITabBar()

    var contentControllers: [FaceTextureTabTypes: FaceRenderer] = [:]

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

    init() {
        super.init(realityConfiguration: .face)

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        buildTabs()
        tabBar.barStyle = .black
        tabBar.isTranslucent = true
        tabBar.delegate = self

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)

        recordingDot.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordingDot)

        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBar)

        initConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * Initialize the first tab and render its content
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.selectedItem = tabBar.items!.first!
        selectedVirtualContent = FaceTextureTabTypes(rawValue: tabBar.selectedItem!.tag)
    }

    /**
     * Build a tab for each texture
     */
    private func buildTabs() {
        var tabBarItems: [UITabBarItem] = []
        tabBarItems.append(UITabBarItem(title: "Bird", image: nil, tag: 0))
        tabBarItems.append(UITabBarItem(title: "Bird White", image: nil, tag: 1))
        tabBarItems.append(UITabBarItem(title: "Half", image: nil, tag: 2))
        tabBarItems.append(UITabBarItem(title: "Half Eyes", image: nil, tag: 3))
        tabBarItems.append(UITabBarItem(title: "Wing", image: nil, tag: 4))
        tabBarItems.append(UITabBarItem(title: "Crest", image: nil, tag: 5))
        tabBarItems.append(UITabBarItem(title: "Football Club", image: nil, tag: 6))

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

    /// MARK - Tabbable (UITabBarDelegate)

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let contentType = FaceTextureTabTypes(rawValue: item.tag)
            else { fatalError("unexpected virtual content tag") }
        selectedVirtualContent = contentType
    }
}

