//
//  Tabbable.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/26/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import ARKit

protocol Tabbable: UITabBarDelegate {
    var tabBar: UITabBar { get set }

    var contentControllers: [FaceTrackingTabTypes: VirtualContentRenderer] { get set }

    var selectedVirtualContent: FaceTrackingTabTypes! { get set }

    var selectedContentController: VirtualContentRenderer { get }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem)
}
