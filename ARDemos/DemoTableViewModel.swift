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

        return viewModels
    }

    private var titles: [String] {
        return ["Single Object Manipulation"]
    }

    init() {}

    func getViewModelForRowAtIndexPath(_ row: Int) -> Any {
        return viewModels[row]
    }

    func getTitleForRowAtIndexPath(_ row: Int) -> String {
        return titles[row]
    }

    func numberOfRows() -> Int {
        return viewModels.count
    }
}
