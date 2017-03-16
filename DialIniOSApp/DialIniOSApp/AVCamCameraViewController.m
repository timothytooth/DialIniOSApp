/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller for camera interface.
*/

@import AVFoundation;
@import Photos;

#import "AVCamCameraViewController.h"
#import "AVCamPreviewView.h"
#import "AVCamPhotoCaptureDelegate.h"
#import "DIALTempStorage.h"
#import "DIALBroadcastObject.h"

static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
	AVCamSetupResultSuccess,
	AVCamSetupResultCameraNotAuthorized,
	AVCamSetupResultSessionConfigurationFailed
};

typedef NS_ENUM( NSInteger, AVCamCaptureMode ) {
	AVCamCaptureModePhoto = 0,
	AVCamCaptureModeMovie = 1
};

typedef NS_ENUM( NSInteger, AVCamLivePhotoMode ) {
	AVCamLivePhotoModeOn,
	AVCamLivePhotoModeOff
};

@interface AVCaptureDeviceDiscoverySession (Utilities)

- (NSInteger)uniqueDevicePositionsCount;

@end

@implementation AVCaptureDeviceDiscoverySession (Utilities)

- (NSInteger)uniqueDevicePositionsCount {
	NSMutableArray<NSNumber *> *uniqueDevicePositions = [NSMutableArray array];
	
	for (AVCaptureDevice *device in self.devices) {
		if (![uniqueDevicePositions containsObject:@(device.position)] ) {
			[uniqueDevicePositions addObject:@(device.position)];
		}
	}
	
	return uniqueDevicePositions.count;
}

@end

@interface AVCamCameraViewController () <AVCaptureFileOutputRecordingDelegate, UITextFieldDelegate>

@property (nonatomic, strong) AVCamPreviewView *previewView;

@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;

// Device configuration.
@property (nonatomic) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;

// Capturing photos.
@property (nonatomic) AVCamLivePhotoMode livePhotoMode;
@property (nonatomic) AVCamCaptureMode captureMode;

@property (nonatomic) AVCapturePhotoOutput *photoOutput;
@property (nonatomic) NSMutableDictionary<NSNumber *, AVCamPhotoCaptureDelegate *> *inProgressPhotoCaptureDelegates;
@property (nonatomic) NSInteger inProgressLivePhotoCapturesCount;


@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@property (nonatomic, strong) UIButton *photoButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, strong) UIButton *addTextButton;
@property (nonatomic, strong) UITextField *editTextField;
@property (nonatomic, strong) UIButton *okayButton;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) NSData *resultData;

/**
 * The layout constraints for the start and end animation states of the edit text field
 */
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *editTextFieldStartLayoutConstraints;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *editTextFieldEndLayoutConstraints;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *editTextFieldMidLayoutConstraints;

@end

// The dispatch block for cleaning up all file stuff
dispatch_block_t cleanup;

@implementation AVCamCameraViewController

#pragma mark View Controller Life Cycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.session = [[AVCaptureSession alloc] init];
	
	NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDuoCamera];
	self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
	
    self.previewView = [[AVCamPreviewView alloc] initWithFrame:CGRectZero];
    self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.previewView];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_previewView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_previewView)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_previewView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_previewView)]];
    
	self.previewView.session = self.session;
	
	self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	
	self.setupResult = AVCamSetupResultSuccess;
	
	/** 
     * Check video authorization status. Video access is required and audio
     * access is optional. If audio access is denied, audio is not recorded
     * during movie recording.
	 */
	switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
		case AVAuthorizationStatusAuthorized: {
			break;
		}
		case AVAuthorizationStatusNotDetermined: {
			/**
             * The user has not yet been presented with the option to grant
             * video access. We suspend the session queue to delay session
			 * setup until the access request has completed.
             *
			 * Note that audio access will be implicitly requested when we
             * create an AVCaptureDeviceInput for audio during session setup.
			 */
			dispatch_suspend(self.sessionQueue);
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
				if (!granted) {
					self.setupResult = AVCamSetupResultCameraNotAuthorized;
				}
				dispatch_resume( self.sessionQueue );
			}];
			break;
		}
		default: {
			self.setupResult = AVCamSetupResultCameraNotAuthorized;
			break;
		}
	}
	
	/**
     * Setup the capture session.
     * In general it is not safe to mutate an AVCaptureSession or any of its
     * inputs, outputs, or connections from multiple threads at the same time.
     *
     * Why not do all of this on the main queue?
     * Because -[AVCaptureSession startRunning] is a blocking call which can
     * take a long time. We dispatch session setup to the sessionQueue so
     * that the main queue isn't blocked, which keeps the UI responsive.
	 */
	dispatch_async(self.sessionQueue, ^{
		[self configureSession];
	});
    
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult) {
            case AVCamSetupResultSuccess: {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case AVCamSetupResultCameraNotAuthorized: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button") style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];

                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"Alert button to open Settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"Unable to capture media", @"Alert message when something goes wrong during capture session configuration");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button") style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
        }
    } );

    UIImage *flipImage = [UIImage imageNamed:@"flip_icon"];
    UIButton *flipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    flipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [flipButton setImage:flipImage forState:UIControlStateNormal];
    [flipButton addTarget:self action:@selector(userDidTapFlipButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flipButton];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=0-[flipButton]-24-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(flipButton)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-24-[flipButton]->=0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(flipButton)]];
    
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    [self addObservers];
}

- (void)viewDidDisappear:(BOOL)animated {
	dispatch_async(self.sessionQueue, ^{
		if (self.setupResult == AVCamSetupResultSuccess) {
			[self.session stopRunning];
			[self removeObservers];
		}
	});
	
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotate {
	// Disable autorotation of the interface when recording is in progress
	return !self.movieFileOutput.isRecording;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	
	if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
		self.previewView.videoPreviewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
	}
}

- (void)configureSession {
	if (self.setupResult != AVCamSetupResultSuccess) {
		return;
	}
	
	NSError *error = nil;
	
	[self.session beginConfiguration];
	
	self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
	// Choose the back dual camera if available, otherwise default to a wide angle camera
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDuoCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
	if (!videoDevice) {
		// If the back dual camera is not available, default to the back wide angle camera
		videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
		
		// In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera
		if (!videoDevice) {
			videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
		}
	}
	AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
	if (!videoDeviceInput) {
		NSLog(@"Could not create video device input: %@", error);
		self.setupResult = AVCamSetupResultSessionConfigurationFailed;
		[self.session commitConfiguration];
		return;
	}
    
	if ([self.session canAddInput:videoDeviceInput]) {
		[self.session addInput:videoDeviceInput];
		self.videoDeviceInput = videoDeviceInput;
		
		dispatch_async( dispatch_get_main_queue(), ^{
			/**
             * Why are we dispatching this to the main queue?
             * Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView
             * can only be manipulated on the main thread.
             * Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
             * on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
             *
             * Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
             * handled by -[AVCamCameraViewController viewWillTransitionToSize:withTransitionCoordinator:].
			 */
			UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
			AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
			if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
				initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
			}
			
			self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
		});
	} else {
		NSLog(@"Could not add video device input to the session");
		self.setupResult = AVCamSetupResultSessionConfigurationFailed;
		[self.session commitConfiguration];
		return;
	}
	
	AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
	if (!audioDeviceInput) {
		NSLog(@"Could not create audio device input: %@", error);
	}
    
	if ([self.session canAddInput:audioDeviceInput]) {
		[self.session addInput:audioDeviceInput];
	} else {
		NSLog(@"Could not add audio device input to the session");
	}
	
	AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
	if ([self.session canAddOutput:photoOutput]) {
		[self.session addOutput:photoOutput];
		self.photoOutput = photoOutput;
		
		self.photoOutput.highResolutionCaptureEnabled = YES;
		self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
		self.livePhotoMode = self.photoOutput.livePhotoCaptureSupported ? AVCamLivePhotoModeOn : AVCamLivePhotoModeOff;
		
		self.inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
		self.inProgressLivePhotoCapturesCount = 0;
	} else {
		NSLog(@"Could not add photo output to the session");
		self.setupResult = AVCamSetupResultSessionConfigurationFailed;
		[self.session commitConfiguration];
		return;
	}
    
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.session canAddOutput:movieFileOutput]) {
        [self.session addOutput:movieFileOutput];
        self.movieFileOutput = movieFileOutput;

        AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoStabilizationSupported) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    } else {
        NSLog(@"Could not add movie file output to the session");
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    
	self.backgroundRecordingID = UIBackgroundTaskInvalid;
	
	[self.session commitConfiguration];
}

- (void)configurePhotoMode{
    dispatch_async(self.sessionQueue, ^{
        /**
         * Remove the AVCaptureMovieFileOutput from the session because movie recording is
         * not supported with AVCaptureSessionPresetPhoto. Additionally, Live Photo
         * capture is not supported when an AVCaptureMovieFileOutput is connected to the session.
         */
        [self.session beginConfiguration];
        [self.session removeOutput:self.movieFileOutput];
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
        [self.session commitConfiguration];
        
        self.movieFileOutput = nil;
        
        if (self.photoOutput.livePhotoCaptureSupported) {
            self.photoOutput.livePhotoCaptureEnabled = YES;
        }
    });
}

- (void)configureVideoMode {
    dispatch_async(self.sessionQueue, ^{
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        
        if ([self.session canAddOutput:movieFileOutput]) {
            [self.session beginConfiguration];
            [self.session addOutput:movieFileOutput];
            self.session.sessionPreset = AVCaptureSessionPresetHigh;
            
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (connection.isVideoStabilizationSupported) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            
            [self.session commitConfiguration];
            
            self.movieFileOutput = movieFileOutput;
        }
    });
}

- (void)resumeInterruptedSession {
    dispatch_async(self.sessionQueue, ^{
        /**
         * The session might fail to start running, e.g., if a phone or FaceTime call is still
         * using audio or video. A failure to start the session running will be communicated via
         * a session runtime error notification. To avoid repeatedly failing to start the session
         * running, we only try to restart the session running in the session runtime error handler
         * if we aren't trying to resume the session running.
         */
        [self.session startRunning];
        self.sessionRunning = self.session.isRunning;
        if (!self.session.isRunning) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = NSLocalizedString( @"Unable to resume", @"Alert message when unable to resume the session running" );
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            });
        } else {
            dispatch_async( dispatch_get_main_queue(), ^{
                //				self.resumeButton.hidden = YES;
            } );
        }
    } );
}

- (void)changeCameraInputDevices {
	dispatch_async(self.sessionQueue, ^{
		AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
		AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
		
		AVCaptureDevicePosition preferredPosition;
		AVCaptureDeviceType preferredDeviceType;
		
		switch (currentPosition) {
			case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront: {
				preferredPosition = AVCaptureDevicePositionBack;
				preferredDeviceType = AVCaptureDeviceTypeBuiltInDuoCamera;
				break;
            }
            case AVCaptureDevicePositionBack: {
				preferredPosition = AVCaptureDevicePositionFront;
				preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
				break;
            }
		}
		
		NSArray<AVCaptureDevice *> *devices = self.videoDeviceDiscoverySession.devices;
		AVCaptureDevice *newVideoDevice = nil;
		
		// First, look for a device with both the preferred position and device type
		for (AVCaptureDevice *device in devices) {
			if (device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType]) {
				newVideoDevice = device;
				break;
			}
		}
		
		// Otherwise, look for a device with only the preferred position
		if (!newVideoDevice) {
			for (AVCaptureDevice *device in devices) {
				if (device.position == preferredPosition) {
					newVideoDevice = device;
					break;
				}
			}
		}
		
		if (newVideoDevice) {
			AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
			
			[self.session beginConfiguration];
			
			// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
			[self.session removeInput:self.videoDeviceInput];
			
			if ( [self.session canAddInput:videoDeviceInput] ) {
				[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
				
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];
				
				[self.session addInput:videoDeviceInput];
				self.videoDeviceInput = videoDeviceInput;
			}
			else {
				[self.session addInput:self.videoDeviceInput];
			}
			
			AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			if ( movieFileOutputConnection.isVideoStabilizationSupported ) {
				movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
			}
			
			/*
				Set Live Photo capture enabled if it is supported. When changing cameras, the
				`livePhotoCaptureEnabled` property of the AVCapturePhotoOutput gets set to NO when
				a video device is disconnected from the session. After the new video device is
				added to the session, re-enable Live Photo capture on the AVCapturePhotoOutput if it is supported.
			 */
			self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
			
			[self.session commitConfiguration];
		}
	} );
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer {
	CGPoint devicePoint = [self.previewView.videoPreviewLayer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:gestureRecognizer.view]];
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
	dispatch_async( self.sessionQueue, ^{
		AVCaptureDevice *device = self.videoDeviceInput.device;
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			/**
             * Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
             * Call set(Focus/Exposure)Mode() to apply the new point of interest.
			 */
			if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
				device.focusPointOfInterest = point;
				device.focusMode = focusMode;
			}
			
			if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
				device.exposurePointOfInterest = point;
				device.exposureMode = exposureMode;
			}
			
			device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
			[device unlockForConfiguration];
		} else {
			NSLog(@"Could not lock device for configuration: %@", error);
		}
	} );
}

- (void)capturePhoto {
    if (self.captureMode != AVCamCaptureModePhoto) {
        [self configurePhotoMode];
    }
    
	/**
     * Retrieve the video preview layer's video orientation on the main queue before
     * entering the session queue. We do this to ensure UI elements are accessed on
     * the main thread and session configuration is done on the session queue.
	 */
	AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.previewView.videoPreviewLayer.connection.videoOrientation;

	dispatch_async(self.sessionQueue, ^{
		// Update the photo output's connection to match the video orientation of the video preview layer
		AVCaptureConnection *photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
		photoOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
		
		// Capture a JPEG photo with flash set to auto and high resolution photo enabled
		AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
		photoSettings.flashMode = AVCaptureFlashModeAuto;
		photoSettings.highResolutionPhotoEnabled = YES;
		if ( photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 ) {
			photoSettings.previewPhotoFormat = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
		}
        
        self.livePhotoMode = AVCamLivePhotoModeOff;
        
		if (self.livePhotoMode == AVCamLivePhotoModeOn && self.photoOutput.livePhotoCaptureSupported) {
            // Live Photo capture is not supported in movie mode
			NSString *livePhotoMovieFileName = [NSUUID UUID].UUIDString;
			NSString *livePhotoMovieFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[livePhotoMovieFileName stringByAppendingPathExtension:@"mov"]];
			photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoMovieFilePath];
		}
		
		// Use a separate object for the photo capture delegate to isolate each capture life cycle
		AVCamPhotoCaptureDelegate *photoCaptureDelegate = [[AVCamPhotoCaptureDelegate alloc] initWithRequestedPhotoSettings:photoSettings willCapturePhotoAnimation:^{
			dispatch_async( dispatch_get_main_queue(), ^{
				self.previewView.videoPreviewLayer.opacity = 0.0;
				[UIView animateWithDuration:0.25 animations:^{
					self.previewView.videoPreviewLayer.opacity = 1.0;
				}];
			} );
		} capturingLivePhoto:^(BOOL capturing) {
			/**
             * Because Live Photo captures can overlap, we need to keep track of the
             * number of in progress Live Photo captures to ensure that the
             * Live Photo label stays visible during these captures.
			 */
			dispatch_async( self.sessionQueue, ^{
				if ( capturing ) {
					self.inProgressLivePhotoCapturesCount++;
				}
				else {
					self.inProgressLivePhotoCapturesCount--;
				}
                
                NSMutableDictionary *dictionary;
                dictionary[@(1)] = @"";
				
				NSInteger inProgressLivePhotoCapturesCount = self.inProgressLivePhotoCapturesCount;
				dispatch_async( dispatch_get_main_queue(), ^{
					if ( inProgressLivePhotoCapturesCount > 0 ) {
//						self.capturingLivePhotoLabel.hidden = NO;
					}
					else if ( inProgressLivePhotoCapturesCount == 0 ) {
//						self.capturingLivePhotoLabel.hidden = YES;
					}
					else {
						NSLog(@"Error: In progress live photo capture count is less than 0" );
					}
				} );
			} );
		} completed:^(AVCamPhotoCaptureDelegate *photoCaptureDelegate) {
            self.resultData = [photoCaptureDelegate.photoData copy];
            [self displayPhotoPreviewWithPhotoCaptureDelegate:photoCaptureDelegate];
		}];
        
		/**
         * The Photo Output keeps a weak reference to the photo capture delegate so
         * we store it in an array to maintain a strong reference to this object
         * until the capture is completed
		 */
		self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = photoCaptureDelegate;
		[self.photoOutput capturePhotoWithSettings:photoSettings delegate:photoCaptureDelegate];
	});
}

- (void)recordVideo {
    if (self.captureMode != AVCamCaptureModeMovie) {
        [self configureVideoMode];
    }
    
	/** 
     * Retrieve the video preview layer's video orientation on the main queue
     * before entering the session queue. We do this to ensure UI elements are
     * accessed on the main thread and session configuration is done on the session queue.
	 */
	AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.previewView.videoPreviewLayer.connection.videoOrientation;
	
	dispatch_async( self.sessionQueue, ^{
        if (!self.movieFileOutput.isRecording) {
			if ([UIDevice currentDevice].isMultitaskingSupported) {
				/**
                 * Setup background task.
                 * This is needed because the [captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                 * callback is not received until AVCam returns to the foreground unless you request background execution time.
                 * This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                 * To conclude this background execution, -[endBackgroundTask:] is called in
                 * -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
				 */
				self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
			}
			
			// Update the orientation on the movie file output video connection before starting recording
			AVCaptureConnection *movieFileOutputConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			movieFileOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
			
			// Start recording to a temporary file
			NSString *outputFileName = [NSUUID UUID].UUIDString;
			NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
			[self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
            self.recording = YES;
		}
	});
}

- (void)stopRecordingVideo {
    if (self.movieFileOutput.isRecording) {
        [self.movieFileOutput stopRecording];
        self.recording = NO;
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
	// Do something?
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
	/**
     * Note that currentBackgroundRecordingID is used to end the background task
     * associated with this recording. This allows a new recording to be started,
     * associated with a new UIBackgroundTaskIdentifier, once the movie file output's
     * `recording` property is back to NO — which happens sometime after this method
     * returns.
     *
     * Note: Since we use a unique file path for each recording, a new recording will
     * not overwrite a recording currently being saved.
	 */
	UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
	self.backgroundRecordingID = UIBackgroundTaskInvalid;
	
	cleanup = ^{
		if ([[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path] ) {
			[[NSFileManager defaultManager] removeItemAtPath:outputFileURL.path error:NULL];
		}
		
		if (currentBackgroundRecordingID != UIBackgroundTaskInvalid) {
			[[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
		}
	};
	
	BOOL success = YES;
	
	if (error) {
		NSLog( @"Movie file finishing error: %@", error );
		success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
	}
    
	if (success) {
        self.resultData = [NSData dataWithContentsOfURL:outputFileURL];
        
        self.player = [AVPlayer playerWithURL:outputFileURL];
        
        if (!self.playerLayer) {
            self.playerLayer = [AVPlayerLayer layer];
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        }
        
        self.playerLayer.player = self.player;

        if (!self.playerView) {
            self.playerView = [[UIView alloc] initWithFrame:CGRectZero];
            self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
        }
        
        [self.playerView.layer addSublayer:self.playerLayer];
        [self.view addSubview:self.playerView];
        
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_playerView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_playerView)]];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_playerView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_playerView)]];

        [self setupMediaPreviewButtons];
        
        [self.player play];
	} else {
		cleanup();
	}
}

- (void)viewWillLayoutSubviews {
    if (!CGRectEqualToRect(self.playerLayer.frame, self.view.frame)) {
        self.playerLayer.frame = self.view.frame;
    }
}

- (void)addObservers {
	[self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    
    /**
     * A session can only run when the app is full screen. It will be interrupted
     * in a multi-app layout, introduced in iOS 9, see also the documentation of
     * AVCaptureSessionInterruptionReason. Add observers to handle these session
     * interruptions and show a preview is paused message. See the documentation
     * of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)playerItemDidPlayToEndTime {
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)removeObservers {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    @try {
        [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    } @catch (NSException *exception) {
       NSLog(@"%@", exception);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context != SessionRunningContext) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)subjectAreaDidChange:(NSNotification *)notification {
	CGPoint devicePoint = CGPointMake(0.5, 0.5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification {
	NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
	NSLog( @"Capture session runtime error: %@", error );
	
	/**
     * Automatically try to restart the session running if media services were
     * reset and the last start running succeeded. Otherwise, enable the user
     * to try to resume the session running.
	 */
	if (error.code == AVErrorMediaServicesWereReset) {
		dispatch_async(self.sessionQueue, ^{
			if ( self.isSessionRunning ) {
				[self.session startRunning];
				self.sessionRunning = self.session.isRunning;
			} else {
				dispatch_async( dispatch_get_main_queue(), ^{
//					self.resumeButton.hidden = NO;
				} );
			}
		} );
	} else {
//		self.resumeButton.hidden = NO;
	}
}

- (void)sessionWasInterrupted:(NSNotification *)notification {
	/**
     * In some scenarios we want to enable the user to resume the session running.
     * For example, if music playback is initiated via control center while
     * using AVCam, then the user can let AVCam resume
     * the session running, which will stop music playback. Note that stopping
     *music playback in control center will not automatically resume the session
     * running. Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
     */
	AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
	NSLog(@"Capture session was interrupted with reason %ld", (long)reason);
	
	if (reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
		reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient) {
        // Do something?
    } else if (reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps) {
		// Do something?
	}
}

- (void)sessionInterruptionEnded:(NSNotification *)notification {
	NSLog(@"Capture session interruption ended");
}

- (void)userDidTapFlipButton {
    [self changeCameraInputDevices];
}

- (void)userDidTapCloseButton {
    [self cleanup];
}

- (void)cleanup {
    if (cleanup) {
        cleanup();
        cleanup = nil;
    }
    
    [self.closeButton removeFromSuperview];
    [self.addTextButton removeFromSuperview];
    
    [self.photoImageView removeFromSuperview];
    
    [self.editTextField removeFromSuperview];
    self.editTextField = nil;
    
    [self.playerLayer removeFromSuperlayer];
    [self.playerView removeFromSuperview];
    
    [self.okayButton removeFromSuperview];
    
    self.player = nil;
    self.resultData = nil;
}

- (void)displayPhotoPreviewWithPhotoCaptureDelegate:(AVCamPhotoCaptureDelegate *)photoCaptureDelegate {
    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIImage *photoImage = [UIImage imageWithData:photoCaptureDelegate.photoData];
        
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        if (currentPosition == AVCaptureDevicePositionFront) {
            UIImage *flippedImage = [UIImage imageWithCGImage:photoImage.CGImage scale:photoImage.scale orientation:UIImageOrientationLeftMirrored];
            
            self.photoImageView = [[UIImageView alloc] initWithImage:flippedImage];
        } else {
            self.photoImageView = [[UIImageView alloc] initWithImage:photoImage];
        }
        
        self.photoImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.photoImageView.clipsToBounds = YES;
        
        [self.view addSubview:self.photoImageView];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_photoImageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_photoImageView)]];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_photoImageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_photoImageView)]];
        
        [self setupMediaPreviewButtons];
    });
}

- (void)setupMediaPreviewButtons {
    if (!self.closeButton) {
        UIImage *closeImage = [UIImage imageNamed:@"close_icon"];
        self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.closeButton setImage:closeImage forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(userDidTapCloseButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view addSubview:self.closeButton];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-24-[_closeButton(24)]->=0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_closeButton)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-24-[_closeButton(24)]->=0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_closeButton)]];
    
    if (!self.addTextButton) {
        UIImage *addTextImage = [UIImage imageNamed:@"add_text_icon"];
        self.addTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.addTextButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.addTextButton setImage:addTextImage forState:UIControlStateNormal];
        [self.addTextButton addTarget:self action:@selector(displayTextFieldForUserInput) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view addSubview:self.addTextButton];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=0-[_addTextButton]-24-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_addTextButton)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-24-[_addTextButton]->=0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_addTextButton)]];
    
    if (!self.okayButton) {
        UIImage *okayImage = [UIImage imageNamed:@"okay_icon"];
        self.okayButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.okayButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.okayButton setImage:okayImage forState:UIControlStateNormal];
        [self.okayButton addTarget:self action:@selector(userDidTapOkayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.view addSubview:self.okayButton];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=0-[_okayButton]-24-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_okayButton)]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[_okayButton]-24-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_okayButton)]];
}

- (void)userDidTapOkayButton {
    DIALTempStorage *tempStorage = [DIALTempStorage sharedStorage];
    DIALBroadcastObject *broadcastObject = [[DIALBroadcastObject alloc] init];
    [broadcastObject setPropertiesWithUsername:@"timothytooth" userProfileImageURL:@"https://static1.squarespace.com/static/50de3e1fe4b0a05702aa9cda/t/50eb2245e4b0404f3771bbcb/1357589992287/ss_profile.jpg" broadcast:self.editTextField.text location:@"Kearny, NJ" broadcastData:self.resultData];
    [tempStorage.tempStorage addObject:broadcastObject];
    
    [self cleanup];
}

- (void)displayTextFieldForUserInput {
    if (self.editTextField) {
        self.editTextField.isFirstResponder ? [self.editTextField resignFirstResponder] : [self.editTextField becomeFirstResponder];
    } else {
        self.editTextField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.editTextField.translatesAutoresizingMaskIntoConstraints = NO;
        self.editTextField.font = [UIFont systemFontOfSize:15];
        self.editTextField.textColor = [UIColor whiteColor];
        self.editTextField.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        self.editTextField.enabled = YES;
        self.editTextField.delegate = self;
        self.editTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.editTextField.textAlignment = NSTextAlignmentCenter;

        [self.view addSubview:self.editTextField];
        
        self.editTextFieldStartLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[_editTextField(32)]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_editTextField)];
        
        [NSLayoutConstraint activateConstraints:self.editTextFieldStartLayoutConstraints];
        [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_editTextField]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_editTextField)]];
        
        [self.view layoutIfNeeded];
        [self.editTextField becomeFirstResponder];
    }
}

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    NSDictionary *keyboardInfo = [notification userInfo];
    
    NSNumber *durationNumber = [keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat duration = [durationNumber doubleValue];
    
    NSValue *keyboardValue = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrame = [keyboardValue CGRectValue];
    
    if (!self.editTextFieldEndLayoutConstraints) {
        self.editTextFieldEndLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[_editTextField(32)]-keyboardHeight-|" options:0 metrics:@{@"keyboardHeight" : @(CGRectGetHeight(keyboardFrame)) } views:NSDictionaryOfVariableBindings(_editTextField)];
    }
    
    [NSLayoutConstraint deactivateConstraints:self.editTextFieldStartLayoutConstraints];
    [NSLayoutConstraint deactivateConstraints:self.editTextFieldMidLayoutConstraints];
    [NSLayoutConstraint activateConstraints:self.editTextFieldEndLayoutConstraints];

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    NSDictionary *keyboardInfo = [notification userInfo];
    
    NSNumber *durationNumber = [keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat duration = [durationNumber doubleValue];

    [NSLayoutConstraint deactivateConstraints:self.editTextFieldEndLayoutConstraints];
    
    if (self.editTextField.text.length == 0) {
        [NSLayoutConstraint activateConstraints:self.editTextFieldStartLayoutConstraints];

        [UIView animateWithDuration:duration animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL __unused finished) {
            [self.editTextField removeFromSuperview];
            self.editTextField = nil;
        }];
        
        self.editTextFieldStartLayoutConstraints = nil;
        self.editTextFieldEndLayoutConstraints = nil;
        self.editTextFieldMidLayoutConstraints = nil;
    } else {
        if (!self.editTextFieldMidLayoutConstraints) {
            NSMutableArray<NSLayoutConstraint *> *midLayoutConstraints = [NSMutableArray array];
            [midLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:self.editTextField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            [midLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_editTextField(32)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_editTextField)]];
            self.editTextFieldMidLayoutConstraints = [midLayoutConstraints copy];
        }
        
        [NSLayoutConstraint activateConstraints:self.editTextFieldMidLayoutConstraints];

        [UIView animateWithDuration:duration animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.editTextField) {
        [textField resignFirstResponder];
        return NO;
    }
    
    return YES;
}

@end
