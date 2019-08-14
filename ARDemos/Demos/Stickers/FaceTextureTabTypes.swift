//
//  FaceTextureTabTypes.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/14/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import UIKit

enum FaceTextureTabTypes: Int {
    /// Each case has a rawValue which corresponds with the tabIndex
    case drund, zach, clown

    func makeRenderer() -> FaceRenderer {
        switch self {
        case .drund:
            return FaceRenderer(displayMode: .drund)
        case .zach:
            return FaceRenderer(displayMode: .zach)
        case .clown:
            return FaceRenderer(displayMode: .clown)
        }
    }
}
