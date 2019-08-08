/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Displays the 3D face mesh geometry provided by ARKit, with a static texture.
 */

import ARKit
import SceneKit

class FaceRenderer: NSObject, VirtualContentRenderer {
    enum DisplayMode {
        case transparent, wireframe
    }

    var displayMode: DisplayMode

    var contentNode: SCNNode?

    init(displayMode: DisplayMode? = nil) {
        self.displayMode = displayMode ?? .transparent
        super.init()

    }

    /// - Tag: CreateARSCNFaceGeometry
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let sceneView = renderer as? ARSCNView,
            let device = sceneView.device,
            anchor is ARFaceAnchor
            else { return nil }

        let faceGeometry = ARSCNFaceGeometry(device: device)
        if let faceGeometry = faceGeometry {
            if displayMode == .wireframe, let material = faceGeometry.firstMaterial {
                // Assign texture map
                material.diffuse.contents = SKTexture(imageNamed: "wireframeTexture")
                material.lightingModel = .physicallyBased
            }

            contentNode = SCNNode(geometry: faceGeometry)

            // Render before other objects to provide allusion of occlusion
            contentNode!.renderingOrder = -1
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
