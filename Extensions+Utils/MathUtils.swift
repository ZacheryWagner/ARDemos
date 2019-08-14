//
//  MathUtils.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/8/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import SceneKit

/**
 * The axis for 3x3 vectors
 */
enum Axis: Int {
    case x = 0
    case y = 1
    case z = 2
}

struct MathUtils {
    /**
     * Finds the angle between two points in 3D space
     * - Returns the angle between two 3 Dimensional points in space in degrees
     * - Parameter pointA: The point for which the first vector will be running to
     * - Parameter pointB: The point for which both vectors will be running from.
                           This is the angle you are calculating for
     * - Returns: a Float for the angle between the two from B
     * 1) calculate the point which would create a right triangle between points a and b
     * 2) create two vectores running from the each point to the connecting point c
     * 3) calculate the dot product of those two vectors
     * 4) calculate the magnitude of each vector
     * 5) find the arccos of the dot product divided by the product of magnitutudes
     */
    static func getAngleBetweenTwo3DPoints(pointA: SCNVector3, pointB: SCNVector3) -> Float {
        // The point which forms a right triangle with A and B
        let pointC = SCNVector3(pointA.x, pointB.y, (pointA.z+pointB.z)/2)

        // Get 3D vector from B to A
        let vectBA = SCNVector3(
            pointA.x - pointB.x,
            pointA.y - pointB.y,
            pointA.z - pointB.z)

        // Get 3D vector from B to C
        let vectBC = SCNVector3(
            pointC.x - pointB.x,
            pointC.y - pointB.y,
            pointC.z - pointB.z)

        // The Dot Product of the two vectors
        let dotProduct: Float =
            (vectBA.x * vectBC.x) + (vectBA.y * vectBC.y) + (vectBA.z * vectBC.z)

        // The magnitude of vector BA
        let magBA: Float =
            sqrtf(powf(vectBA.x, 2) + powf(vectBA.y, 2) + powf(vectBA.z, 2))

        // The magnitude of vector BC
        let magBC: Float =
            sqrtf(powf(vectBC.x, 2) + powf(vectBC.y, 2) + powf(vectBC.z, 2))

        return acos(dotProduct/(magBA * magBC)) * 100
    }
}

extension Array where Element == vector_float3 {
    /**
     * Sorts the array from least to greatest
     * - Parameter axis: The axis we are sorting for
     */
    func sortFromLeastToGreatestForAxis(_ axis: Axis) -> Array {
        var sortedVectors: [vector_float3] = []

        switch axis {
        case .x:
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.x > sortedVectors[sortedVectors.count - 1].x {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.x > vector.x }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        case .y:
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.y > sortedVectors[sortedVectors.count - 1].y {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.y > vector.y }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        case .z:
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.z > sortedVectors[sortedVectors.count - 1].z {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.z > vector.z }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        }
        return sortedVectors
    }

    /**
     * Sorts the array of vectors from least to greatest absolute value for specified axes.
     * If two axes are specified it sorts by the absolute value of the sum of the two
     * - Parameter axes: the one or two axis we are sorting by
     */
    func sortByAbsoluteValuesForAxes(axes: Axis...) -> Array? {
        // Guard extranious or duplicate axes
        guard axes.count < 3,
            axes.count > 1 ? axes[0] != axes[1] : true
            else { return nil }

        var sortedVectors: [vector_float3] = []

        // The one or two axes to loop through
        let axes: (Axis, Axis?) = (axes[0], axes.count > 1 ? axes[1] : nil)

        /*
         * Loop through the specified columns only
         * Sort the array as we compare the values by absolute value
         */
        switch axes {
        case (.x, nil):
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.x > sortedVectors[sortedVectors.count - 1].x {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.x > vector.x }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        case (.y, nil):
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.y > sortedVectors[sortedVectors.count - 1].y {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.y > vector.y }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        case (.z, nil):
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.z > sortedVectors[sortedVectors.count - 1].z {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.z > vector.z }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        case (.x, .y?):
            for vector in self {
                if sortedVectors.isEmpty ||
                    abs(vector.x + vector.y) >
                    abs(sortedVectors[sortedVectors.count - 1].x + sortedVectors[sortedVectors.count - 1].y) {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { abs($0.x + $0.y) > abs(vector.x + vector.y) }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }

        case (.x, .z?):
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.x + vector.z >
                    sortedVectors[sortedVectors.count - 1].x + sortedVectors[sortedVectors.count - 1].z {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.x + $0.z > vector.x + vector.z }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        case (.y, .z?):
            for vector in self {
                if sortedVectors.isEmpty ||
                    vector.y + vector.z >
                    sortedVectors[sortedVectors.count - 1].y + sortedVectors[sortedVectors.count - 1].z {
                    sortedVectors.append(vector)
                } else {
                    if let index = sortedVectors.firstIndex(where: { $0.y + $0.z > vector.y + vector.z }) {
                        sortedVectors.insert(vector, at: index)
                    }
                }
            }
        default:
            return nil
        }
        return sortedVectors
    }
}

extension FloatingPoint {
    /**
     * Convert from degrees to radians
     */
    func toRadians() -> Self {
        return self * .pi / 180
    }
}

extension vector_float3 {
    /**
     * Convert from a vector_float3 to a SCNVector3
     */
    func toSceneVector() -> SCNVector3 {
        return SCNVector3(x: self.x, y: self.y, z: self.z)
    }
}
