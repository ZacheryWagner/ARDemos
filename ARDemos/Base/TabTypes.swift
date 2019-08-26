//
//  TabTypes.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/19/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import UIKit

enum FaceTrackingTabTypes: Int {
    /// Each case has a rawValue which corresponds with the tabIndex
    case transforms, texture, geometry, videoTexture, blendShape

    func makeRenderer() -> VirtualContentRenderer {
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

enum ObjectShowcaseTabTypes: Int {
    /// Each case has a rawValue which corresponds with the tabIndex
    case trophy, well

    func makeRenderer() -> ModelRenderer {
        switch self {
        case .trophy:
            return ModelRenderer(displayMode: .trophy)
        case .well:
            return ModelRenderer(displayMode: .well)
        }
    }
}

enum FaceTextureTabTypes: Int {
    /// Each case has a rawValue which corresponds with the tabIndex
    case liverpoolBirdTexture
    case liverpoolBirdWhiteTexture
    case liverpoolHalf_halfTexture
    case liverpoolHalf_halfEyesTexture
    case liverpoolWingTexture
    case liverpoolCrestStickerTexture
    case liverpoolFootballClubStickerTexture

    func makeRenderer() -> FaceRenderer {
        switch self {
        case .liverpoolBirdTexture:
            return FaceRenderer(displayMode: .liverpoolBirdTexture)
        case .liverpoolBirdWhiteTexture:
            return FaceRenderer(displayMode: .liverpoolBirdWhiteTexture)
        case .liverpoolHalf_halfTexture:
            return FaceRenderer(displayMode: .liverpoolHalf_halfTexture)
        case .liverpoolHalf_halfEyesTexture:
            return FaceRenderer(displayMode: .liverpoolHalf_halfEyesTexture)
        case .liverpoolWingTexture:
            return FaceRenderer(displayMode: .liverpoolWingTexture)
        case .liverpoolCrestStickerTexture:
            return FaceRenderer(displayMode: .liverpoolCrestStickerTexture)
        case .liverpoolFootballClubStickerTexture:
            return FaceRenderer(displayMode: .liverpoolFootballClubStickerTexture)

        }
    }
}
