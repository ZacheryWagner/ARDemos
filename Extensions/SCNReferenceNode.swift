//
//  SCNReferenceNode.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/22/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import SceneKit

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
