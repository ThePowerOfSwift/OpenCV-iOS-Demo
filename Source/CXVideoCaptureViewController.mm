//
//  CXVideoCaptureViewController.h
//  OpenCV-iOS-demo
//
//  Created by 刘伟 on 12/01/2017.
//  Copyright © 2017 上海凌晋信息技术有限公司. All rights reserved.
//

#import "CXVideoCaptureViewController.h"

#import "CXVideoCaptureView.h"

#import "CXVideoCaptureViewController+CaptureImage.h"
#import "CXVideoCaptureViewController+CaptureDocument.h"
#import "CXVideoCaptureViewController+Configuration.h"

#import "CXImagePreviewViewController.h"
#import "CXVideoPreviewViewController.h"

#import "UIView+CXExt.h"
#import "CXStringUtils.h"
#import "CXImageUtils.h"
#import "CXFileUtils.h"

#import <SVProgressHUD/SVProgressHUD.h>

@interface CXVideoCaptureViewController()<CXVideoCaptureViewDelegate>
{
    NSTimer *_calVideoDurationTimer;
    CXVideoCaptureView *rootView;
    BOOL statusBarHidden;
    UIStatusBarStyle statusBarStyle;
}

@end

@implementation CXVideoCaptureViewController

#pragma mark - ViewController lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    
    rootView = [[CXVideoCaptureView alloc] initWithFrame:self.view.frame andCameraMediaType:self.cameraMediaType];
    rootView.delegate = self;
    [self.view addSubview:rootView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setupAVCapture];
    [self reloadCameraConfiguration];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self tearDownAVCapture];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (NSString *)videoPath {
//    NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//    
//    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
//                      stringByAppendingPathComponent:directory];
//    
//    NSString *moviePath = [basePath stringByAppendingPathComponent:
//                           [NSString stringWithFormat:@"CX_VIDEO%i.mov",(int)[NSDate date].timeIntervalSince1970]];
    return [CXFileUtils getMediaObjectPathWithType:self.cameraMediaType];
}

- (void)startVideoCapture {
    [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[self videoPath]] recordingDelegate:rootView];
}

- (void)stopVideoCapture {
    if ([self.movieFileOutput isRecording]) {
        [self.movieFileOutput stopRecording];
    }
}

#pragma mark - Sensor control

// Set torch on or off (if supported)
- (void)setTorchOn:(BOOL)torch
{
    NSError *error = nil;
    if ([_videoDevice hasTorch]) {
        BOOL locked = [_videoDevice lockForConfiguration:&error];
        if (locked) {
            _videoDevice.torchMode = (torch)? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
            [_videoDevice unlockForConfiguration];
        }
    }
    
    if ([self torchOn]) {
        [rootView.torchButton setImage:[CXImageUtils imageNamed:@"record_flash_on"] forState:UIControlStateNormal];
    }else{
        [rootView.torchButton setImage:[CXImageUtils imageNamed:@"record_flash_off"] forState:UIControlStateNormal];
    }
}

// Return YES if the torch is on
- (BOOL)torchOn
{
    return (_videoDevice.torchMode == AVCaptureTorchModeOn);
}

/**
  Choose front/back Camera
 */
- (void)setCamera:(AVCaptureDevicePosition)position
{
    if ([self currentCameraPosition] == position)
    {
        return;
    }
    
    if (_captureSession)
    {
        AVCaptureDevice *cameraDevice = [self cameraWithPosition:position];
        
        if (cameraDevice == nil) {
            NSLog(@"ANTBETA:No any camera is working");
            return;
        }
        
        [_captureSession beginConfiguration];
        
        // Remove current camera
        if (_videoInput)
        {
            [_captureSession removeInput:_videoInput];
            _videoInput = nil;
        }
        
        _videoDevice = cameraDevice;
        
        // Create device input
        NSError *error = nil;
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:&error];
        [_captureSession addInput:_videoInput];
        
        [_captureSession commitConfiguration];
    }
}

#pragma mark - Private

- (AVCaptureDevicePosition)currentCameraPosition
{
    if (!_captureSession) {
        return AVCaptureDevicePositionUnspecified;
    }
    
    NSArray *inputs = _captureSession.inputs;
    
    AVCaptureDevicePosition position = AVCaptureDevicePositionUnspecified;
    
    for (AVCaptureDeviceInput *input in inputs )
    {
        AVCaptureDevice *device = input.device;
        
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            position = device.position;
            break;
        }
    }
    return position;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
            return device;
    }
    return nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.cameraMediaType == kCameraMediaTypeDocument)
    {
        [self processDocumentBuffer:sampleBuffer];
    }
    /*
    else if(self.cameraMediaType == kCameraMediaTypePhoto)
    {
        NSLog(@"kCameraMediaTypePhoto");
    }
    else if(self.cameraMediaType == kCameraMediaTypeVideo)
    {
        NSLog(@"kCameraMediaTypeVideo");
    }
     */
}

#pragma mark - AVCapture initilization and destroy

- (BOOL)setupAVCapture
{
    // Get capture devices from current iPhone
    AVCaptureDevice *cameraDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    
    if (cameraDevice == nil) {
        NSLog(@"ANTBETA:No any camera is working");
        return NO;
    }
    
    self.videoDevice = cameraDevice;
    
    // Create a video input with the video device.
    NSError *error = nil;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&error];
    if (error) {
        NSLog(@"ANTBETA: An error occured when create an AVCaptureDeviceInput with '_videoDevice': %@",[error description]);
        return NO;
    }
    
    // Create a CaptureSession, It coordinates the flow of data between audio and video inputs and outputs.
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    // Connect up inputs and outputs
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
    
    // Create the preview layer
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setFrame:self.view.bounds];
    
    NSLog(@"%@",NSStringFromCGRect(self.view.bounds));
    
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    self.view.backgroundColor = [UIColor blackColor];
    [self.view.layer insertSublayer:self.videoPreviewLayer atIndex:0];
    
    [self.captureSession startRunning];
    
    return YES;
}

// Tear down the video capture session
- (void)tearDownAVCapture
{
    [self.captureSession stopRunning];
    for (AVCaptureOutput *output in self.captureSession.outputs) {
        [self.captureSession removeOutput:output];
    }
    for (AVCaptureInput *input in self.captureSession.inputs) {
        [self.captureSession removeInput:input];
    }
    
    [_rectangleCALayer removeFromSuperlayer];
    _rectangleCALayer = nil;
    
    [_videoPreviewLayer removeFromSuperlayer];
    _videoPreviewLayer = nil;
    
    _videoInput = nil;
    _audioInput = nil;
    
    _videoOutput = nil;
    _audioDataOutput = nil;
    
    _videoDevice = nil;
    _audioDevice = nil;
    
    _movieFileOutput = nil;
    _stillImageOutput = nil;
    
    _captureSession = nil;
}

#pragma mark - CXVideoCaptureViewDelegate

// It will be triggered when you switch the Tabs by swipe view to right or left with your finger
- (void) onViewChanged:(CXCameraMediaType)type
{
    NSLog(@"onViewChanged");
    self.cameraMediaType = type;
    [self reloadCameraConfiguration];
}

/* The follow events will be triggered when you click relative Buttons */
-(void) onCancelButtonClick
{
    [UIApplication sharedApplication].statusBarHidden = statusBarHidden;
    [UIApplication sharedApplication].statusBarStyle = statusBarStyle;
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void) onTorchButtonClick
{
    [self setTorchOn:![self torchOn]];
}
-(void) onCameraButtonClick
{
    AVCaptureDevicePosition position = [self currentCameraPosition];
    
    if ( position == AVCaptureDevicePositionBack)
    {
        [self setCamera:AVCaptureDevicePositionFront];
    }else{
        [self setCamera:AVCaptureDevicePositionBack];
    }
}
-(void) onVideoCaptureStartButtonClick
{
    [self startVideoCapture];
}
-(void) onVideoCaptureStopButtonClick
{
    [self stopVideoCapture];
}
-(void) onCaptureImageButtonCick
{
    __weak typeof(self) weakSelf = self;
    [self captureImageWithCompletionHander:^(NSString *imageFilePath) {
        CXImagePreviewViewController *previewController = [[CXImagePreviewViewController alloc] init];
        previewController.imagePath = imageFilePath;
        previewController.cameraMediaType = self.cameraMediaType;
        previewController.cameraCaptureResult = weakSelf.cameraCaptureResult;
        previewController.statusBarStyle = statusBarStyle;
        previewController.statusBarHidden = statusBarHidden;
        [weakSelf.navigationController pushViewController:previewController animated:NO];
    }];
}
-(void) onCaptureDocumentButtonCick
{
    __weak typeof(self) weakSelf = self;
    [self captureDocumentWithCompletionHander:^(NSString *imageFilePath) {
        CXImagePreviewViewController *previewController = [[CXImagePreviewViewController alloc] init];
        previewController.imagePath = imageFilePath;
        previewController.cameraMediaType = self.cameraMediaType;
        previewController.cameraCaptureResult = weakSelf.cameraCaptureResult;
        previewController.statusBarStyle = statusBarStyle;
        previewController.statusBarHidden = statusBarHidden;
        [weakSelf.navigationController pushViewController:previewController animated:NO];
    }];
}
-(void) didStartVideoRecording
{
    if (_calVideoDurationTimer == nil) {
        _calVideoDurationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleCalVideoDuration:) userInfo:nil repeats:YES];
    }
}

-(void) didStopVideoRecording:(NSString *)videoPath
{
    if (_calVideoDurationTimer != nil) {
        [_calVideoDurationTimer invalidate];
        _calVideoDurationTimer = nil;
    }
    
    // 录制时间必须大于5s
    float totalSeconds = CMTimeGetSeconds(self.movieFileOutput.recordedDuration);
    if (totalSeconds < 5) {
        // Video's recorded duration must greater than 5 seconds.
        [CXFileUtils deleteFileWithFilePath:videoPath];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"录制时间需要大于5秒" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            rootView.recordDurationLabel.text = @"00:00:00";
        }];
        [alert addAction:action1];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    // mov 转 mp4
    NSURL *inputUrl = [NSURL fileURLWithPath:videoPath];
    
    NSURL *outputUrl = [NSURL fileURLWithPath:[videoPath stringByReplacingOccurrencesOfString:@".mov" withString:@".mp4"]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
        [SVProgressHUD showWithStatus:@"处理中,请稍后..."];
    });
    
    [self compressVideo:inputUrl outputURL:outputUrl handler:^(AVAssetExportSession *exportSession) {
        
        switch (exportSession.status)
        {
            case AVAssetExportSessionStatusCompleted:
            {
                NSLog(@"AVAssetExportSessionStatusCompleted");
                [CXFileUtils deleteFileWithFilePath:inputUrl.path];
                dispatch_async(dispatch_get_main_queue(), ^{
                    rootView.recordDurationLabel.text = @"00:00:00";
                    [SVProgressHUD dismiss];
                    CXVideoPreviewViewController *previewController = [[CXVideoPreviewViewController alloc] init];
                    NSURL *videoUrl = [NSURL fileURLWithPath:exportSession.outputURL.path];
                    previewController.videoUrl = videoUrl;
                    previewController.cameraMediaType = self.cameraMediaType;
                    previewController.cameraCaptureResult = self.cameraCaptureResult;
                    previewController.statusBarStyle = statusBarStyle;
                    previewController.statusBarHidden = statusBarHidden;
                    [self.navigationController pushViewController:previewController animated:NO];
                });
            }
                break;
            default:
            {
                NSLog(@"AVAssetExportSessionStatus :%ld",(long)exportSession.status);
                
                [CXFileUtils deleteFileWithFilePath:inputUrl.path];
                [CXFileUtils deleteFileWithFilePath:outputUrl.path];
                dispatch_async(dispatch_get_main_queue(), ^{
                    rootView.recordDurationLabel.text = @"00:00:00";
                    [SVProgressHUD showErrorWithStatus:@"出错了，请重新录制"];
                    [SVProgressHUD dismissWithDelay:2];
                });
            }
                break;
        }
        
    }];
    
}

- (void)compressVideo:(NSURL*)inputURL
            outputURL:(NSURL*)outputURL
              handler:(void (^)(AVAssetExportSession*))completion  {
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        completion(exportSession);
    }];
}

#pragma mark - Private

- (void)handleCalVideoDuration:(NSTimer*)timer
{
    float totalSeconds = CMTimeGetSeconds(self.movieFileOutput.recordedDuration);
    rootView.recordDurationLabel.text = [CXStringUtils stringFromInterval:totalSeconds];
}


@end
