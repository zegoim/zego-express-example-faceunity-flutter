//
//  ZegoBeautyCamera.m
//  Pods-Runner
//
//  Created by lizhanpeng@ZEGO on 2020/9/16.
//

#import "ZegoBeautyCamera.h"
#import "FURenderer.h"
#import "authpack.h"
#import <objc/message.h>

@interface ZegoBeautyCamera()<AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_queue_t _sampleBufferCallbackQueue;
    int fuItems[1];
    int frameID;
}

@property (nonatomic, strong) id customVideoCaptureManager;
@property (nonatomic, assign) SEL sendCVPixelBufferSelector;

@property (nonatomic, assign) BOOL isCaptured;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *output;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureInput *activateInput;
@property (nonatomic, assign) BOOL isFrontCamera;

@end

@implementation ZegoBeautyCamera

+ (void)setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int err = [[FURenderer shareRenderer] setupWithData:nil dataSize:0 ardata:nil authPackage:&g_auth_package authSize:sizeof(g_auth_package) shouldCreateContext:YES];
        NSData *ai_face_processor = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ai_face_processor.bundle" ofType:nil]];
        [FURenderer loadAIModelFromPackage:(void*)ai_face_processor.bytes size:(int)ai_face_processor.length aitype:FUAITYPE_FACEPROCESSOR];

        NSLog(@"FU SET UP err: %d", err);
    });
}

- (instancetype)init {
    if(self = [super init]) {
        _sampleBufferCallbackQueue = dispatch_queue_create("im.zego.customCamera.outputCallbackQueue", DISPATCH_QUEUE_SERIAL);
        _isFrontCamera = YES;
        frameID = 0;

        NSString *path = [[NSBundle mainBundle] pathForResource:@"face_beautification" ofType:@"bundle"];
        fuItems[0] = [FURenderer itemWithContentsOfFile:path];

        Class managerClass = NSClassFromString(@"ZegoCustomVideoCaptureManager");
        SEL managerSelector = NSSelectorFromString(@"sharedInstance");
        id sharedManager = ((id (*)(id, SEL))objc_msgSend)(managerClass, managerSelector);
        self.customVideoCaptureManager = sharedManager;

        self.sendCVPixelBufferSelector = NSSelectorFromString(@"sendCVPixelBuffer:timestamp:channel:");
    }

    return self;
}

- (void) dealloc {
    NSLog(@"Zego Camera Dealloc");

    [FURenderer destroyItem:fuItems[0]];
    fuItems[0] = 0;
}

- (BOOL)switchCamera:(AVCaptureDevicePosition)position {
    NSError * error;

    if(position == AVCaptureDevicePositionUnspecified)
        return NO;

    AVCaptureDevice * inActivityDevice = [self cameraWithPosition:position];
    if (!inActivityDevice)
        return NO;

    AVCaptureDeviceInput * deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inActivityDevice error:&error];
    if(!deviceInput) {
        return NO;
    }

    //开始装置设备。

    [self.session beginConfiguration];

    [self.session removeInput:self.activateInput];

    if ([self.session canAddInput:deviceInput]) {

        [self.session addInput:deviceInput];

        self.activateInput = deviceInput;

        if (deviceInput.device.position == AVCaptureDevicePositionFront) {
            self.isFrontCamera = YES;
        } else {
            self.isFrontCamera = NO;
        }

        // 使用前置摄像头时，需调用 SDK 设置预览水平镜像，否则无需使用镜像
        //[self.client setVideoMirrorMode: self.isFrontCamera ? 0 : 2];

        AVCaptureVideoDataOutput *output = self.output;
        AVCaptureConnection *captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];

        if (captureConnection.isVideoOrientationSupported) {
            captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }

        if (deviceInput.device.position == AVCaptureDevicePositionFront) {
            captureConnection.videoMirrored = YES;
        } else {
            captureConnection.videoMirrored = NO;
        }

    } else {

        //切换失败时，重新将之前的设备添加到会话Session中。
        [self.session addInput:self.activateInput];

    }

    //装置完毕后，需要提交此次的修改。
    [self.session commitConfiguration];

    [FURenderer onCameraChange];
    return YES;

}

- (void)setCameraFrameRate:(int)framerate {
    if (!self.input.device) {
        NSLog(@"Camera is not actived");
        return;
    }

    NSArray<AVFrameRateRange *> *ranges = self.input.device.activeFormat.videoSupportedFrameRateRanges;
    AVFrameRateRange *range = [ranges firstObject];

    if (!range) {
        NSLog(@"videoSupportedFrameRateRanges is empty");
        return;
    }

    if (framerate > range.maxFrameRate || framerate < range.minFrameRate) {
        NSLog(@"Unsupport framerate: %d, range is %.2f ~ %.2f", framerate, range.minFrameRate, range.maxFrameRate);
        return;
    }

    NSError *error = [[NSError alloc] init];
    if (![self.input.device lockForConfiguration:&error]) {
        NSLog(@"AVCaptureDevice lockForConfiguration failed. errCode:%ld, domain:%@", error.code, error.domain);
    }
    self.input.device.activeVideoMinFrameDuration = CMTimeMake(1, framerate);
    self.input.device.activeVideoMaxFrameDuration = CMTimeMake(1, framerate);
    [self.input.device unlockForConfiguration];

    NSLog(@"Set framerate to %d", framerate);
}

- (void)setWhitenParam:(double)whiten {
    [FURenderer itemSetParam:fuItems[0] withName:@"color_level" value:@(whiten)];
}

- (void)setRedParam:(double)red {
    [FURenderer itemSetParam:fuItems[0] withName:@"red_level" value:@(red)];
}

- (void)setBlurParam:(double)blur {
    [FURenderer itemSetParam:fuItems[0] withName:@"blur_level" value:@(blur)];
}

- (void)setEnlargingParam:(double)enlarging {
    [FURenderer itemSetParam:fuItems[0] withName:@"eye_enlarging" value:@(enlarging)];
}

- (void)setThinningParam:(double)thinning {
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_thinning" value:@(thinning)];
}

- (void)setVParam:(double)v {
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_v" value:@(v)];
}

- (void)setNarrowParam:(double)narrow {
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_narrow" value:@(narrow)];
}

- (void)setSmallParam:(double)small {
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_small" value:@(small)];
}

- (void)setChinParam:(double)chin {
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_chin" value:@(chin)];
}

- (void)setForeheadParam:(double)forehead {
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_forehead" value:@(forehead)];
}

- (void)setNoseParam:(double)nose {
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_nose" value:@(nose)];
}

- (void)setMouthParam:(double)mouth {
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_mouth" value:@(mouth)];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {

    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice * device in devices) {

        if (device.position == position) {
            return device;
        }

    }

    return nil;
}

- (void)resetBeautyOption {
    [self loadDefaultBeautyOption];
}

- (void)loadDefaultBeautyOption {

    [FURenderer itemSetParam:fuItems[0] withName:@"heavy_blur" value:@(0)];
    [FURenderer itemSetParam:fuItems[0] withName:@"skin_detect" value:@(1)];

    // 0 ~ 2
    [FURenderer itemSetParam:fuItems[0] withName:@"color_level" value:@(1.0)]; // 美白 (0~2)
    // 0 ~ 2
    [FURenderer itemSetParam:fuItems[0] withName:@"red_level" value:@(0.5)]; // 红润 (0~2)
    // 0 ~ 6
    [FURenderer itemSetParam:fuItems[0] withName:@"blur_level" value:@(4.2)]; // 磨皮 (0~6)


    [FURenderer itemSetParam:fuItems[0] withName:@"face_shape" value:@(4)];
    [FURenderer itemSetParam:fuItems[0] withName:@"face_shape_level" value:@(1.0)];

    [FURenderer itemSetParam:fuItems[0] withName:@"eye_enlarging" value:@(0.4)]; //大眼 (0~1)
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_thinning" value:@(0)]; //瘦脸 (0~1)
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_v" value:@(0.5)]; //v脸 (0~1)
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_narrow" value:@(0)]; //窄脸 (0~1)  demo窄脸、小脸上限0.5
    [FURenderer itemSetParam:fuItems[0] withName:@"cheek_small" value:@(0)]; //小脸 (0~1)
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_chin" value:@(0.3)]; /**下巴 (0~1)*/
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_forehead" value:@(0.3)];/**额头 (0~1)*/
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_nose" value:@(0.5)];/**鼻子 (0~1)*/
    [FURenderer itemSetParam:fuItems[0] withName:@"intensity_mouth" value:@(0.4)];/**嘴型 (0~1)*/
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (AVCaptureDeviceInput *)input {
    if (!_input) {
            NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

            // Note: This demonstration selects the front camera. Developers should choose the appropriate camera device by themselves.
            NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", AVCaptureDevicePositionFront]];
            if (captureDeviceArray.count == 0) {
                NSLog(@"Failed to get camera");
                return nil;
            }
            AVCaptureDevice *camera = captureDeviceArray.firstObject;

            NSError *error = nil;
            AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
            if (error) {
                NSLog(@"Conversion of AVCaptureDevice to AVCaptureDeviceInput failed");
                return nil;
            }
            _input = captureDeviceInput;
        }
        return _input;
}

- (AVCaptureVideoDataOutput *)output {
    if (!_output) {
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
        [videoDataOutput setSampleBufferDelegate:self queue:_sampleBufferCallbackQueue];
        _output = videoDataOutput;
    }
    return _output;
}

#pragma mark ZegoCustomVideoCaptureDelegate

- (void)onStart:(int)channel {
    self.isCaptured = YES;

    [self.session beginConfiguration];

    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    }

    AVCaptureDeviceInput *input = self.input;

    if ([self.session canAddInput:input]) {
        [self.session addInput:input];

        self.activateInput = input;

        if (input.device.position == AVCaptureDevicePositionFront) {
            self.isFrontCamera = YES;
        } else {
            self.isFrontCamera = NO;
        }

        // 相机帧率默认值为30
        [self setCameraFrameRate:30];

    }


    AVCaptureVideoDataOutput *output = self.output;

    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }

    AVCaptureConnection *captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];

    if (captureConnection.isVideoOrientationSupported) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }

    if (input.device.position == AVCaptureDevicePositionFront) {
        captureConnection.videoMirrored = YES;
    } else {
        captureConnection.videoMirrored = NO;
    }

    [self.session commitConfiguration];

    if (!self.session.isRunning) {
        [self.session startRunning];
    }

    [self loadDefaultBeautyOption];
}

- (void)onStop:(int)channel {

    if (self.session.isRunning) {
        [self.session stopRunning];
    }

    self.isCaptured = NO;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    // 切换了前后摄像头之后，可能会有几帧延迟，此时摄像头状态和实际出帧标记会有不一致的情况，丢弃这几帧
    if((self.isFrontCamera && connection.videoMirrored == NO) || (!self.isFrontCamera && connection.videoMirrored))
        return;


    CVPixelBufferRef processedBuffer = [[FURenderer shareRenderer] renderPixelBuffer:buffer withFrameId:frameID items:fuItems itemCount:1];
    frameID += 1;

    if(self.isCaptured) {

        // [[ZegoCustomVideoCaptureManager]  sendCVPixelBuffer:processedBuffer timestamp:timeStamp];
        // [[ZegoCustomVideoCaptureManager] sharedInstance] sendCVPixelBuffer:processedBuffer timestamp:timeStamp];
        // [[ZegoCustomVideoCaptureManager sharedInstance] sendCVPixelBuffer:processedBuffer timestamp:timeStamp channel: 0];

        // 走 runtime 解决 Swift 动态库工程无法 import 其他库的问题
        ((void (*)(id, SEL, CVPixelBufferRef, CMTime, int))objc_msgSend)(self.customVideoCaptureManager, self.sendCVPixelBufferSelector, processedBuffer, timeStamp, 0);
    }
}


@end
