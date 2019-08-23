//
//  ModelRenderer.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/19/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import ARKit
import SceneKit

class ModelRenderer: NSObject, VirtualContentRenderer {
    enum DisplayMode {
        case trophy, well
    }

    var displayMode: DisplayMode

    var contentNode: SCNNode?

    init(displayMode: DisplayMode) {
        self.displayMode = displayMode
        super.init()

    }
    /// - Tag: CreateARSCNFaceGeometry
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARPlaneAnchor else { return nil }

        switch displayMode {
        case .trophy:
            contentNode = SCNReferenceNode(named: "champions_league_trophy")
        case .well:
            contentNode = SCNReferenceNode(named: "well")
        }
        return contentNode
    }

    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = node.geometry as? ARSCNFaceGeometry,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }

        faceGeometry.update(from: faceAnchor.geometry)
    }
}
