//
//  Recordable.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/16/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import UIKit
import ARVideoKit

protocol Recordable {
    /// Handles recording
    var recorder: RecordAR? { get set }

    /// Getsure recognizer for handling starting/stopping recording
    var longPressGestureRecognizer: UILongPressGestureRecognizer { get set }

    /// Dot indicating video is being recorded
    var recordingDot: UIView { get set }

    /// Timer for `recordingDot` strobe animation
    var recordingStrobeTimer: Timer? { get set }

    /// Interval to strobe the live dot
    var recordingStrobeInterval: Double { get set }

    /**
     * Start the timer for the record dot strobe
     */
    func startRecordStrobe()

    /**
     * Stop the timer for the record dot strobe
     */
    func stopRecordStrobe()
}
