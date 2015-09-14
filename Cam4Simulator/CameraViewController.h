////
////  CameraViewController.h
////  Cam4Simulator
////
////  Created by MacMan on 9/14/15.
////  Copyright (c) 2015 MacManApp. All rights reserved.
////
//
//#import <UIKit/UIKit.h>
//
//@interface CameraViewController : UIViewController
//
//@end


#import <UIKit/UIKit.h>

@protocol CameraDelegate

- (void)cameraStartedRunning;
- (void)didTakePhoto:(UIImage *)photo;

@end

@interface CameraViewController : UIViewController

@property (nonatomic, weak) id<CameraDelegate> delegate;

- (void)startCamera;
- (void)stopCamera;
- (BOOL)isCameraRunning;


@end



