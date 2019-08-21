//
//  DemoTableVIewController.swift
//  ARDemos
//
//  Created by Zachery Wagner on 7/18/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit

class DemoTableViewController: UITableViewController {
    private let viewModel: DemoTableViewModel

    init(viewModel: DemoTableViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Mark: - TableView functions

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = viewModel.getTitleForRowAtIndexPath(indexPath.row)
        return cell
    }

    /**
     * Open the view controller for the row
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            let vm = ObjectManipulationViewModel()
            let vc = ObjectManipulationViewController(viewModel: vm)
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = ObjectShowcaseViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 2:
            let vc = RocketLaunchViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 3:
            let vc = FaceTrackingViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 4:
            let vc = ObjectStickerViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 5:
            let vc = FaceTextureViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            print("There was an indexing error in the `DemoTableViewController`")
        }
    }
}
