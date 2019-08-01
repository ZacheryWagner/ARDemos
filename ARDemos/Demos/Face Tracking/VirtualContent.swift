//
//  VirtualContent.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/19/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import ARKit
import SceneKit

enum VirtualContentType: Int {
    /// Each case has a rawValue which corresponds with the tabIndex
    case transforms, texture, geometry, videoTexture, blendShape

    func makeController() -> VirtualContentController {
        switch self {
        case .transforms:
            return TransformVisualization()
        case .texture:
            return TexturedFace()
        case .geometry:
            return FaceOcclusionOverlay()
        case .videoTexture:
            return VideoTexturedFace()
        case .blendShape:
            return BlendShapeCharacter()
        }
    }

    /**
     * Builds a tab
     * Returns a tuple with title and image for building the corresponding tab
     */
    func getTabInfoForTabValue(tabValue: Int) -> (title: String, image: UIImage?) {
        switch tabValue {
        case 0:
            return (title: "Transform", image: UIImage(named: "transforms"))
        case 1:
            return (title: "Texture", image: UIImage(named: "texture"))
        case 2:
            return (title: "3D Overlay", image: UIImage(named: "geometry"))
        case 3:
            return (title: "Video Texture", image: UIImage(named: "videoTexture"))
        case 4:
            return (title: "Blend Shapes", image: UIImage(named: "blendShapes"))
        default:
            return (title: "Empty", nil)
        }
    }
}

/// For forwarding `ARSCNViewDelegate` messages to the object controlling the currently visible virtual content.
protocol VirtualContentController: ARSCNViewDelegate {
    /// The root node for the virtual content.
    var contentNode: SCNNode? { get set }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}
