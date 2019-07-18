//
//  SingleObjectManipulationViewModel.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/16/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import SceneKit

class SingleObjectManipulationViewModel {
    /// List of cube textures to toggle between
    private(set) var nodeTextures: [[SCNMaterial]] = [[]]

    /// The index representing the current texture on display
    private var textureIndex: Int = 0

    /// Length of a side of the box
    private(set) var boxDimension: CGFloat = 0.05

    /// The current angle of the box
    var currentAngleY: Float = 0.0

    var lightingButtonText: String {
        return isLightingActive ? "Disable Lighting" : "Enable Lighting"
    }

    /// Is the scenekit lighting active
    var isLightingActive = true

    var debugButtonText: String {
        return isDebugActive ? "Disable Debug" : "Enable Debug"
    }

    /// Is the scenekit lighting active
    var isDebugActive = true

    /// Color for buttons
    private(set) var buttonColor = UIColor.violet?.withAlphaComponent(0.7)

    init() {
        buildTextures()
    }

    private func buildTextures() {
        let numFaces = 6
        for i in 1...numFaces {
            var faceTextures: [SCNMaterial] = []
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "valveDefault")
            faceTextures.append(material)

            if i == numFaces {
                nodeTextures.append(faceTextures)
            }
        }

        for i in 1...numFaces {
            var faceTextures: [SCNMaterial] = []
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "mcDirt")
            faceTextures.append(material)

            if i == numFaces {
                nodeTextures.append(faceTextures)
            }
        }

        for i in 1...numFaces {
            var faceTextures: [SCNMaterial] = []
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "zachDrund")
            faceTextures.append(material)

            if i == numFaces {
                nodeTextures.append(faceTextures)
            }
        }

        for i in 1...numFaces {
            var faceTextures: [SCNMaterial] = []
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.violet
            faceTextures.append(material)

            if i == numFaces {
                nodeTextures.append(faceTextures)
            }
        }

        for i in 1...numFaces {
            var faceTextures: [SCNMaterial] = []
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.hardRed
            faceTextures.append(material)

            if i == numFaces {
                nodeTextures.append(faceTextures)
            }
        }
    }

    func incrimentTextureIndex() {
        if textureIndex == 5 {
            textureIndex = 0
        } else {
            textureIndex += 1
        }
    }

    func getTextureForCurrentIndex() -> [SCNMaterial] {
        return nodeTextures[textureIndex]
    }
}
