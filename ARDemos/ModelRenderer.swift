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
        guard let sceneView = renderer as? ARSCNView,
            let device = sceneView.device,
            anchor is ARPlaneAnchor
            else { return nil }

        let faceGeometry = ARSCNFaceGeometry(device: device)
        if let faceGeometry = faceGeometry {
            if let material = faceGeometry.firstMaterial {
                switch displayMode {
                case .trophy:
                    material.diffuse.contents = SKTexture(imageNamed: "wireframeTexture")
                    material.lightingModel = .physicallyBased
                case .well:
                    material.diffuse.contents = SKTexture(imageNamed: "wireframeTexture")
                    material.lightingModel = .physicallyBased
                }
            }

            contentNode = SCNNode(geometry: faceGeometry)

            // Render before other objects to provide allusion of occlusion
            contentNode?.renderingOrder = -1
            return contentNode
        }
        return nil
    }

    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = node.geometry as? ARSCNFaceGeometry,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }

        faceGeometry.update(from: faceAnchor.geometry)
    }
}
