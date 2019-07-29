/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple cartoon character animated using ARKit blend shapes.
*/

import Foundation
import SceneKit
import ARKit

/// - Tag: BlendShapeCharacter
class BlendShapeCharacter: NSObject, VirtualContentController {
    
    var contentNode: SCNNode?

    private var originalJawY: Float = 0
    
    private var jawNode: SCNNode?
    private var eyeLeftNode: SCNNode?
    private var eyeRightNode: SCNNode?
    
    private var jawHeight: Float {
        if let jawNode = jawNode {
            let (min, max) = jawNode.boundingBox
            return max.y - min.y
        }
        return 0
    }

    private func setNodes() {
        jawNode = contentNode!.childNode(withName: "jaw", recursively: true)
        eyeLeftNode = contentNode!.childNode(withName: "eyeLeft", recursively: true)
        eyeRightNode = contentNode!.childNode(withName: "eyeRight", recursively: true)
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARFaceAnchor else { return nil }

        contentNode = SCNReferenceNode(named: "robotHead")
        setNodes()

        originalJawY = jawNode?.position.y ?? 0

        return contentNode
    }
    
    /**
     * Blend the robohead into the face for blinking and jaw moevement
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        let blendShapes = faceAnchor.blendShapes
        guard let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float,
            let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float,
            let jawOpen = blendShapes[.jawOpen] as? Float
            else { return }

        eyeLeftNode?.scale.z = 1 - eyeBlinkLeft
        eyeRightNode?.scale.z = 1 - eyeBlinkRight
        jawNode?.position.y = originalJawY - jawHeight * jawOpen
    }
}
