//
//  DemoTableViewModel.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/18/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit

class DemoTableViewModel {
    private var titles: [String] {
        return ["Single Object Manipulation", "Rocket Launch"]
    }

    init() {}

    func getTitleForRowAtIndexPath(_ row: Int) -> String {
        guard titles.indices.contains(row) else { return  ""}

        return titles[row]
    }

    func numberOfRows() -> Int {
        return titles.count
    }
}
