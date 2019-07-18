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
    private var viewModels: [Any] {
        var viewModels: [Any] = []

        viewModels.append(SingleObjectManipulationViewModel())
        viewModels.append(RocketLaunchViewModel())

        return viewModels
    }

    private var titles: [String] {
        return ["Single Object Manipulation", "Rocket Launch"]
    }

    init() {}

    // TODO: Add better error handling for this
    func getViewModelForRowAtIndexPath(_ row: Int) -> Any {
        guard viewModels.indices.contains(row) else { return ""}

        return viewModels[row]
    }

    func getTitleForRowAtIndexPath(_ row: Int) -> String {
        guard titles.indices.contains(row) else { return  ""}

        return titles[row]
    }

    func numberOfRows() -> Int {
        return viewModels.count
    }
}
