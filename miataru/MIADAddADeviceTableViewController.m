//
//  MIADAddADeviceTableViewController.m
//  miataru
//
//  Created by Daniel Kirstenpfad on 08.09.13.
//  Copyright (c) 2013 Miataru. All rights reserved.
//

#import "MIADAddADeviceTableViewController.h"
#import "MIADScanQRCodeViewController.h"
#import "KnownDevice.h"
#import <AVFoundation/AVFoundation.h>

@interface MIADAddADeviceTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *DeviceNameTextField;

@property (weak, nonatomic) IBOutlet UITextField *DeviceIDTextField;

//@property (strong) AVCaptureSession *captureSession;
//
//@property (strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation MIADAddADeviceTableViewController

- (void) addADeviceFromURLType:(NSString*)inDevice
{
   NSLog(@"AddADeviceFromURLType: %@", inDevice);
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)CancelButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //[self.delegate addADeviceTableViewControllerDidFinish:self knownDevice:nil];
    
}
- (IBAction)SaveButtonAction:(id)sender
{
    KnownDevice *newDevice = nil;
    
    if ([self.DeviceNameTextField.text length] && [self.DeviceIDTextField.text length])
    {
        newDevice = [KnownDevice DeviceWithName:self.DeviceNameTextField.text DeviceID:self.DeviceIDTextField.text];
        [self.delegate addADeviceTableViewControllerDidFinish:self knownDevice:newDevice];
        [self dismissViewControllerAnimated:YES completion:nil];
    }

}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ModalToScanQRCode"])
    {
        ((MIADScanQRCodeViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0]).delegate = self;
    }
}

- (void) ScanQRCodeControllerDidFinish:(MIADScanQRCodeViewController*)inController scannedDeviceID:(NSString*)DeviceID;
{
    [self.DeviceIDTextField setText:[DeviceID uppercaseString]];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"%i-%i",indexPath.row,indexPath.section);
    
//    if (indexPath.row == 0 && indexPath.section == 1)
//    {
//        self.captureSession = [[AVCaptureSession alloc] init];
//        AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//        NSError *error = nil;
//        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
//        if(videoInput)
//            [self.captureSession addInput:videoInput];
//        else
//        {
//            NSLog(@"Error: %@", error);
//            return;
//        }
//        //Turn on point autofocus for middle of view
//        [videoCaptureDevice lockForConfiguration:&error];
//        CGPoint point = CGPointMake(0.5,0.5);
//        [videoCaptureDevice setFocusPointOfInterest:point];
//        [videoCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
//        [videoCaptureDevice unlockForConfiguration];
//        
//        AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
//        [self.captureSession addOutput:metadataOutput];
//        [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
//        [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
//        
//        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
//        _previewLayer.frame = self.view.bounds;
//        [self.view.layer addSublayer:_previewLayer];
//        
//        [self.captureSession startRunning];
//    }
}

@end
