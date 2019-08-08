//
//  MathUtils.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/8/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import simd

struct MathUtils {
    /**
     * Returns the angle between two 3 Dimensional points in space
     * - Parameter pointA: The point for which the first vector will be running to
     * - Parameter pointB: The point for which both vectors will be running from
     * - Returns: a Float for the angle between the two from B
     * 1) calculate the point which would create a right triangle between points a and b
     * 2) create two vectores running from the each point to the connecting point c
     * 3) calculate the dot product of those two vectors
     * 4) calculate the magnitude of each vector
     * 5) find the arccos of the dot product divided by the product of magnitutudes
     */
    static func getAngleBetweenTwo3DPoints(pointA: vector_float3, pointB: vector_float3) -> Float {
        // The point which forms a right triangle with A and B
        let pointC: vector_float3 = vector3(pointA.x, pointB.y, (pointA.z+pointB.z)/2)

        // Get 3D vector from B to A
        let vectBA: vector_float3 = vector3(
            pointA.x - pointB.x,
            pointA.y - pointB.y,
            pointA.z - pointB.z)

        // Get 3D vector from B to C
        let vectBC: vector_float3 = vector3(
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

        return acos(dotProduct/(magBA * magBC)) *100
    }
}
