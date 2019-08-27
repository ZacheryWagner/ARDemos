//
//  SceneKitExtensions.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/27/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

extension SCNMatrix4 {
    /**
     Create a 4x4 matrix from CGAffineTransform, which represents a 3x3 matrix
     but stores only the 6 elements needed for 2D affine transformations.

     [ a  b  0 ]     [ a  b  0  0 ]
     [ c  d  0 ]  -> [ c  d  0  0 ]
     [ tx ty 1 ]     [ 0  0  1  0 ]
     .               [ tx ty 0  1 ]

     Used for transforming texture coordinates in the shader modifier.
     (Needs to be SCNMatrix4, not SIMD float4x4, for passing to shader modifier via KVC.)
     */
    init(_ affineTransform: CGAffineTransform) {
        self.init()
        m11 = Float(affineTransform.a)
        m12 = Float(affineTransform.b)
        m21 = Float(affineTransform.c)
        m22 = Float(affineTransform.d)
        m41 = Float(affineTransform.tx)
        m42 = Float(affineTransform.ty)
        m33 = 1
        m44 = 1
    }
}

extension SCNNode {
    var extents: float3 {
        let (min, max) = boundingBox
        return float3(max) - float3(min)
    }
}

extension SCNReferenceNode {
    /**
     * Create a reference node from a scene resource name
     */
    convenience init(named resourceName: String, loadImmediately: Bool = true) {
        let url = Bundle.main.url(forResource: resourceName, withExtension: "scn", subdirectory: "Models.scnassets")!
        self.init(url: url)!
        if loadImmediately {
            self.load()
        }
    }
}

// MARK: - ARSCNView extensions

extension ARSCNView {

    func smartHitTest(_ point: CGPoint) -> ARHitTestResult? {

        // Perform the hit test.
        let results = hitTest(point, types: [.existingPlaneUsingGeometry])

        // 1. Check for a result on an existing plane using geometry.
        if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }) {
            return existingPlaneUsingGeometryResult
        }

        // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
        let infinitePlaneResults = hitTest(point, types: .existingPlane)

        if let infinitePlaneResult = infinitePlaneResults.first {
            return infinitePlaneResult
        }

        // 3. As a final fallback, check for a result on estimated planes.
        return results.first(where: { $0.type == .estimatedHorizontalPlane })
    }
}

