////
////  CameraViewController.m
////  Cam4Simulator
////
////  Created by MacMan on 9/14/15.
////  Copyright (c) 2015 MacManApp. All rights reserved.
////
//
//#import "CameraViewController.h"
//
//@implementation CameraViewController
//
//@end



#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h>



@interface CameraViewController ()

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) UIView *cameraPreviewFeedView;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic) UILabel *noCameraInSimulatorMessage;


@end


@implementation NSThread (Helper)
+ (void)executeOnMainThread:(void (^)())block
{
    if (!block) return;
    
    if ([[NSThread currentThread] isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^ {
            block();
        });
    }
}

@end


@implementation CameraViewController {
    BOOL _simulatorIsCameraRunning;
    
    
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.noCameraInSimulatorMessage.hidden = !TARGET_IPHONE_SIMULATOR;
}

- (UILabel *)noCameraInSimulatorMessage
{
    if (!_noCameraInSimulatorMessage) {
        CGFloat labelWidth = self.view.bounds.size.width * 0.75f;
        CGFloat labelHeight = 60;
        _noCameraInSimulatorMessage = [[UILabel alloc] initWithFrame:CGRectMake(self.view.center.x - labelWidth/2.0f, self.view.bounds.size.height - 75 - labelHeight, labelWidth, labelHeight)];
        _noCameraInSimulatorMessage.numberOfLines = 0; // wrap
        _noCameraInSimulatorMessage.text = @"Sorry, no camera in the simulator... Crying allowed.";
        _noCameraInSimulatorMessage.backgroundColor = [UIColor clearColor];
        _noCameraInSimulatorMessage.hidden = YES;
        _noCameraInSimulatorMessage.textColor = [UIColor whiteColor];
        _noCameraInSimulatorMessage.shadowOffset = CGSizeMake(1, 1);
        _noCameraInSimulatorMessage.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_noCameraInSimulatorMessage];
    }
    
    return _noCameraInSimulatorMessage;
}

- (void)startCamera
{
    if (TARGET_IPHONE_SIMULATOR) {
        _simulatorIsCameraRunning = YES;
        [NSThread executeOnMainThread: ^{
            [self.delegate cameraStartedRunning];
        }];
        return;
    }
    
    if (!self.cameraPreviewFeedView) {
        self.cameraPreviewFeedView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.cameraPreviewFeedView.center = self.view.center;
        self.cameraPreviewFeedView.backgroundColor = [UIColor clearColor];
        
        if (![self.view.subviews containsObject:self.cameraPreviewFeedView]) {
            [self.view addSubview:self.cameraPreviewFeedView];
        }
    }
    
    if (![self isCameraRunning]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            if (!self.captureSession) {
                
                self.captureSession = [AVCaptureSession new];
                self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
                
                NSError *error = nil;
                AVCaptureDeviceInput *newVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                if (!newVideoInput) {
                    // Handle the error appropriately.
                    NSLog(@"ERROR: trying to open camera: %@", error);
                }
                
                AVCaptureStillImageOutput *newStillImageOutput = [AVCaptureStillImageOutput new];
                NSDictionary *outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
                [newStillImageOutput setOutputSettings:outputSettings];
                
                if ([self.captureSession canAddInput:newVideoInput]) {
                    [self.captureSession addInput:newVideoInput];
                }
                
                if ([self.captureSession canAddOutput:newStillImageOutput]) {
                    [self.captureSession addOutput:newStillImageOutput];
                    self.stillImageOutput = newStillImageOutput;
                }
                
                NSNotificationCenter *notificationCenter =
                [NSNotificationCenter defaultCenter];
                
                [notificationCenter addObserver: self
                                       selector: @selector(onVideoError:)
                                           name: AVCaptureSessionRuntimeErrorNotification
                                         object: self.captureSession];
                
                if (!self.captureVideoPreviewLayer) {
                    [NSThread executeOnMainThread: ^{
                        self.captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
                        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                        self.captureVideoPreviewLayer.frame = self.cameraPreviewFeedView.bounds;
                        [self.cameraPreviewFeedView.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];
                    }];
                }
            }
            
            // this will block the thread until camera is started up
            [self.captureSession startRunning];
            
            [NSThread executeOnMainThread: ^{
                [self.delegate cameraStartedRunning];
            }];
        });
    } else {
        [NSThread executeOnMainThread: ^{
            [self.delegate cameraStartedRunning];
        }];
    }
}


- (void)stopCamera
{
    if (TARGET_IPHONE_SIMULATOR) {
        _simulatorIsCameraRunning = NO;
        return;
    }
    
    if (self.captureSession && [self.captureSession isRunning]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
            [self.captureSession stopRunning];
        });
    }
}

- (BOOL)isCameraRunning
{
    if (TARGET_IPHONE_SIMULATOR) return _simulatorIsCameraRunning;
    
    if (!self.captureSession) return NO;
    
    return self.captureSession.isRunning;
}

- (void)onVideoError:(NSNotification *)notification
{
    NSLog(@"Video error: %@", notification.userInfo[AVCaptureSessionErrorKey]);
}

- (void)takePhoto
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (TARGET_IPHONE_SIMULATOR) {
            [self.delegate didTakePhoto: [UIImage imageNamed:@"Simulator_OriginalPhoto@2x.jpg"]];
            return;
        }
        
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in self.stillImageOutput.connections)
        {
            for (AVCaptureInputPort *port in [connection inputPorts])
            {
                if ([[port mediaType] isEqual:AVMediaTypeVideo] )
                {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection)
            {
                break;
            }
        }
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                           completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
         {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             
             [self.delegate didTakePhoto: [UIImage imageWithData: imageData]];
         }];
    });
}
@end



