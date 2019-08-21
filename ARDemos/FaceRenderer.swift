/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Displays the 3D face mesh geometry provided by ARKit, with a static texture.
 */

import ARKit
import SceneKit

class FaceRenderer: NSObject, VirtualContentRenderer {
    enum DisplayMode {
        case transparent
        case wireframe
        case liverpoolBirdTexture
        case liverpoolBirdWhiteTexture
        case liverpoolHalf_halfTexture
        case liverpoolHalf_halfEyesTexture
        case liverpoolWingTexture
        case liverpoolCrestStickerTexture
        case liverpoolFootballClubStickerTexture
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
            if let material = faceGeometry.firstMaterial {
                switch displayMode {
                case .transparent:
                    material.colorBufferWriteMask = []
                case .wireframe:
                    material.diffuse.contents = SKTexture(imageNamed: "wireframe")
                    material.lightingModel = .physicallyBased
                case .liverpoolBirdTexture:
                    material.diffuse.contents = SKTexture(imageNamed: "liverpoolBirdTexture")
                    material.lightingModel = .physicallyBased
                case .liverpoolBirdWhiteTexture:
                    material.diffuse.contents = SKTexture(imageNamed: "liverpoolBirdWhiteTexture")
                    material.lightingModel = .physicallyBased
                case .liverpoolHalf_halfTexture:
                    material.diffuse.contents = SKTexture(imageNamed: "liverpoolHalf_halfTexture")
                    material.lightingModel = .physicallyBased
                case .liverpoolHalf_halfEyesTexture:
                    material.diffuse.contents = SKTexture(imageNamed: "liverpoolHalf_halfEyesTexture")
                    material.lightingModel = .physicallyBased
                case .liverpoolWingTexture:
                    material.diffuse.contents = SKTexture(imageNamed: "liverpoolWingTexture")
                    material.lightingModel = .physicallyBased
                case .liverpoolCrestStickerTexture:
                    material.diffuse.contents = SKTexture(imageNamed: "liverpoolCrestStickerTexture")
                    material.lightingModel = .physicallyBased
                case .liverpoolFootballClubStickerTexture:
                    material.diffuse.contents = SKTexture(imageNamed: "liverpoolFootballClubStickerTexture")
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
