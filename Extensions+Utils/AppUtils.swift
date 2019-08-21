//
//  AppUtils.swift
//  ARDemos
//
//  Created by Zachery Wagner on 8/18/19.
//  Copyright © 2019 Zachery Wagner. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos

class AppUtils {
    static func checkCameraAndMicAccess(required: Bool = false, onAuthorized: @escaping () -> Void, onDenied: (() -> Void)? = nil) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)

        if (cameraStatus == .notDetermined) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { authorized in
                DispatchQueue.main.async {
                    if authorized {
                        checkCameraAndMicAccess(onAuthorized: onAuthorized, onDenied: onDenied)
                    } else if required {
                        let alert = UIAlertController(title: "alert-title-camera-required", message: "alert-message-camera-required", preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "Sick", style: .default, handler: { (UIAlertAction) in
                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }

                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                if #available(iOS 10.0, *) {
                                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                                } else {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                        }))
                    } else {
                        print("maybe show alert about the permission being helpful for a better experience")
                        print("option to go to settings")
                    }
                }
            })
        } else if (micStatus == .notDetermined) {
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { authorized in
                DispatchQueue.main.async {
                    if authorized {
                        checkCameraAndMicAccess(onAuthorized: onAuthorized, onDenied: onDenied)
                    } else if required {
                        let alert = UIAlertController(title: "alert-title-camera-required", message: "alert-message-camera-required", preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "Sick", style: .default, handler: { (UIAlertAction) in
                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }

                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                if #available(iOS 10.0, *) {
                                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                                } else {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                        }))
                    } else {
                        print("maybe show alert about the permission being helpful for a better experience")
                        print("option to go to settings")
                    }
                }
            })
        }

        if (cameraStatus == .authorized && micStatus == .authorized) {
            onAuthorized()
        } else if (cameraStatus == .denied) {
            let alert = UIAlertController(title: "alert-title-camera-required", message: "alert-message-camera-required", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Sick", style: .default, handler: { (UIAlertAction) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    } else {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }))
        } else if (micStatus == .denied) {
            let alert = UIAlertController(title: "alert-title-camera-required", message: "alert-message-camera-required", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Sick", style: .default, handler: { (UIAlertAction) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    } else {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }))
        }
    }

    /**
     * Ensures the user has given the application access to their photos
     * - Parameter onAuthorized: Block to execute if access has been granted
     * - Parameter onDenied: Block to execute if access has been denied
     */
    static func checkPhotoAccess(onAuthorized: @escaping () -> Void, onDenied: (() -> Void)? = nil) {
        let status = PHPhotoLibrary.authorizationStatus()

        if (status == .authorized) {
            onAuthorized()
        } else if (status == .denied) {
            let alert = UIAlertController(title: "alert-title-camera-required", message: "alert-message-camera-required", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Sick", style: .default, handler: { (UIAlertAction) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    } else {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }))
            onDenied?()
        } else if (status == .notDetermined) {
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                DispatchQueue.main.async {
                    if (newStatus == .authorized) {
                        onAuthorized()
                    } else {
                        onDenied?()
                        let alert = UIAlertController(title: "alert-title-camera-required", message: "alert-message-camera-required", preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "Sick", style: .default, handler: { (UIAlertAction) in
                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }

                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                if #available(iOS 10.0, *) {
                                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                                } else {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                        }))
                    }
                }
            })
        }
    }
}
