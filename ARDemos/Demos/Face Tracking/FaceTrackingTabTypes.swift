//
//  FaceTrackingTabTypes.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/19/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import UIKit

enum FaceTrackingTabTypes: Int {
    /// Each case has a rawValue which corresponds with the tabIndex
    case transforms, texture, geometry, videoTexture, blendShape

    func makeController() -> VirtualContentRenderer {
        switch self {
        case .transforms:
            return TransformVisualization()
        case .texture:
            return FaceRenderer(displayMode: .wireframe)
        case .geometry:
            return FaceOcclusionOverlay()
        case .videoTexture:
            return VideoTexturedFace()
        case .blendShape:
            return BlendShapeCharacter()
        }
    }
}
