/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller for camera interface.
*/

@import UIKit;

/**
 * This protocol is used to send messages back to the page view controller so that elements 
 * from the tab bar that is layered on top of everything can be hidden if needed
 */
@protocol AVCamCameraViewControllerProtocol

/**
 * This method is called on the delegate when a photo or video is captured
 */
- (void)userDidCaptureMedia;

/**
 * This method is called on the delegate when the photo or video overlay is dismissed
 */
- (void)userDidDismissCapturedMediaOverlay;

@end

/**
 * This view controller handles the capturing of photos and video, and handles all user action
 * associated with the function
 */
@interface AVCamCameraViewController : UIViewController

/**
 * The delegate
 */
@property (nonatomic, weak) id<AVCamCameraViewControllerProtocol> delegate;

/**
 * This indicates whether a video is currently recording
 */
@property (nonatomic, getter=isRecording) BOOL recording;

/**
 * This method captures a photo
 */
- (void)capturePhoto;

/**
 * This method starts recording a video
 */
- (void)recordVideo;

/**
 * This method stops recording a video
 */
- (void)stopRecordingVideo;

@end
