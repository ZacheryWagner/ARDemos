//
//  FaceTextureTabBarButtonView.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/13/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit

class FaceTextureTabBarButtonView: UIView {
    let shapeLayer = CAShapeLayer()

    init() {
        super.init(frame: .zero)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 100,y: 100), radius: CGFloat(20), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)

        shapeLayer.path = circlePath.cgPath

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 5.0

       layer.addSublayer(shapeLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
