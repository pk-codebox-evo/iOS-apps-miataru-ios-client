//
//  MIADHistoryViewController.m
//  miataru
//
//  Created by Daniel Kirstenpfad on 08.11.13.
//  Copyright (c) 2013 Miataru. All rights reserved.
//

#import "MIADHistoryViewController.h"
#import "PassedTimeDateFormatter.h"
#import "PositionPin.h"

@implementation MIADHistoryViewController

@synthesize HistoryMapView;
@synthesize mapScaleView;
@synthesize rainbow_hue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationItem.hidesBackButton = false;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadDeviceID];
    
    rainbow_hue = 0.0;  // the hue to start with...
    
	// Do any additional setup after loading the view.
    NSInteger map_type = [[NSUserDefaults standardUserDefaults] integerForKey:@"map_type"];
    
    switch (map_type)
    {
        case 1:
            [HistoryMapView setMapType:MKMapTypeStandard];
            break;
        case 2:
            [HistoryMapView setMapType:MKMapTypeHybrid];
            break;
        case 3:
            [HistoryMapView setMapType:MKMapTypeSatellite];
            break;
        default:
            [HistoryMapView setMapType:MKMapTypeStandard];
            break;
    }
    
    // here comes the interesting part
	// get a handle to the map scale view of our mapView (by eventually installing one first)
	mapScaleView = [LXMapScaleView mapScaleForMapView:HistoryMapView];
    mapScaleView.position = kLXMapScalePositionBottomRight;
	mapScaleView.style = kLXMapScaleStyleBar;
    //mapScaleView.style = kLXMapScaleStyleTapeMeasure;
    mapScaleView.alpha = 0.7;
    mapScaleView.maxWidth = 150;
    
    [mapScaleView update];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"Device History View appears...");
    
    NSInteger map_type = [[NSUserDefaults standardUserDefaults] integerForKey:@"map_type"];
    
    switch (map_type)
    {
        case 1:
            [HistoryMapView setMapType:MKMapTypeStandard];
            break;
        case 2:
            [HistoryMapView setMapType:MKMapTypeHybrid];
            break;
        case 3:
            [HistoryMapView setMapType:MKMapTypeSatellite];
            break;
        default:
            [HistoryMapView setMapType:MKMapTypeStandard];
            break;
    }
    
    [self GetLocationForDeviceFromMiataruServer:self.HistoryDevice];

}

#pragma mark MapView Delegate Methods
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    //NSLog(@"viewForAnnotation");
    
    // Don't mess with user location
	if(![annotation isKindOfClass:[PositionPin class]])
        return nil;
    
    PositionPin *a = (PositionPin *)annotation;
    static NSString *defaultPinID = @"StandardIdentifier";
    
    // Create the ZSPinAnnotation object and reuse it
    ZSPinAnnotation *pinView = (ZSPinAnnotation *)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
    if (pinView == nil){
        pinView = [[ZSPinAnnotation alloc] initWithAnnotation:annotation reuseIdentifier:defaultPinID];
    }
    
    // Set the type of pin to draw and the color
    pinView.annotationType = a.type;
    pinView.annotationColor = a.color;
    pinView.canShowCallout = YES;
    
    return pinView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    //NSLog(@"didaddannotation");
    //    MKAnnotationView *annotationView = [views objectAtIndex:0];
    //    id <MKAnnotation> mp = [annotationView annotation];
    //    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([mp coordinate], 1000,1000);
    //    [mapView setRegion:region animated:YES];
    
}

#pragma mark MapScale
- (void)mapView:(MKMapView*)aMapView regionDidChangeAnimated:(BOOL)aAnimated
{
	// the map scale will retrieve the current state of the mapView it is attached to
	// and update itself accordingly
	[mapScaleView update];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self.responseData = [[NSMutableData alloc] init];
    //[self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSError *err = nil;
    NSDictionary* jsonArray = [NSJSONSerialization
                               JSONObjectWithData:self.responseData //1
                               options:NSJSONReadingMutableContainers
                               error:&err];
    
    NSArray* MiataruLocations = [jsonArray objectForKey:@"MiataruLocation"]; //2

    // how many days should we display?
    long number_of_days_to_show = [[NSUserDefaults standardUserDefaults] integerForKey:@"history_number_of_days"];
    
    if (MiataruLocations != nil && [MiataruLocations class] != [NSNull class])
    {
        // iterate through all available locations...
        for (id MiataruLocation in MiataruLocations) {
            if (MiataruLocation != nil)
            {
                NSString* Lat = [MiataruLocation objectForKey:@"Latitude"];
                NSString* Lon = [MiataruLocation objectForKey:@"Longitude"];
                NSString* Timestamp = [MiataruLocation objectForKey:@"Timestamp"];
                //NSString* DeviceID = [MiataruLocation objectForKey:@"Device"];
                
                NSDate* TimestampOfPin = [NSDate dateWithTimeIntervalSince1970:[Timestamp doubleValue]];

//                UIColor *color = [UIColor colorWithHue:0.5
//                                          saturation:1.0
//                                          brightness:1.0
//                                          alpha:1.0];
                
                if ( [PassedTimeDateFormatter isWithinDayRange:TimestampOfPin DayRange:number_of_days_to_show] )
                {
                    NSString *TimeString = [PassedTimeDateFormatter dateToStringInterval:TimestampOfPin];
                    
                    if (Lat != nil && Lon != nil && [Lat class] != [NSNull class] && [Lon class] != [NSNull class])
                    {
                        // now get long and lat out and add pin to mapview
                        CLLocationCoordinate2D DeviceCoordinates;
                        
                        DeviceCoordinates.latitude = [Lat doubleValue];
                        DeviceCoordinates.longitude = [Lon doubleValue];
                        if (DeviceCoordinates.latitude != 0.0 && DeviceCoordinates.longitude != 0.0)
                        {
                            // Add the annotation to our map view
                            PositionPin *newAnnotation = [[PositionPin alloc] initWithTitle:TimeString andCoordinate:DeviceCoordinates andColor:self.HistoryDevice.DeviceColor];
                            [HistoryMapView addAnnotation:newAnnotation];
                            //NSLog(@"Added Annotation...");
                        }
                    }
                }
            }
        }
        // zoom to fit all map annotations...
        [HistoryMapView showAnnotations:HistoryMapView.annotations animated:NO];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Connection failed: %@",error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - GetLocationForDeviceFromMiataruServer

- (void)GetLocationForDeviceFromMiataruServer:(KnownDevice*)device
{
    /*
     ￼{"MiataruGetLocation": [{"Device":"7b8e6e0ee5296db345162dc2ef652c1350761823"}]}
     */
    //int number_of_items_to_show = [[NSUserDefaults standardUserDefaults] integerForKey:@"history_number_of_items"];

    // get as much as possible, but up to 1024 entries...
    NSString* GetLocationJSONContent = [NSString stringWithFormat:@"{\"MiataruConfig\":{\"RequestMiataruDeviceID\": \"%@\"},\"MiataruGetLocationHistory\": {\"Device\":\"%@\",\"Amount\": \"%d\"}}",self.device_id,device.DeviceID,1024];
    
    self.responseData = [NSMutableData data];
    
    NSString* miataru_server_url = [[NSUserDefaults standardUserDefaults] stringForKey:@"miataru_server_url"];
    
    while ([miataru_server_url hasSuffix:@"/"])
    {
        if ( [miataru_server_url length] > 0)
            miataru_server_url = [miataru_server_url substringToIndex:[miataru_server_url length] - 1];
    }
    
    NSMutableURLRequest *detailrequest =
    [[NSMutableURLRequest alloc] initWithURL:
     [NSURL URLWithString:[NSString stringWithFormat:@"%@/v1/GetLocationHistory", miataru_server_url]]];
    
    
    [detailrequest setHTTPMethod:@"POST"];
    
    [detailrequest setValue:[NSString
                             stringWithFormat:@"%lu", (unsigned long)[GetLocationJSONContent length]]
         forHTTPHeaderField:@"Content-length"];
    
    [detailrequest setValue:@"application/json"
         forHTTPHeaderField:@"Content-Type"];
    
    
    [detailrequest setHTTPBody:[GetLocationJSONContent dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [NSURLConnection connectionWithRequest:detailrequest delegate:self];
    
    //NSLog(@"%@", GetLocationJSONContent);
    
    NSLog(@"Getting LocationHistory from to Miataru Service...");
}

#pragma mark Persistent State for device ID

- (NSURL*)applicationDataDirectory {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
                                             inDomains:NSUserDomainMask];
    NSURL* appSupportDir = nil;
    NSURL* appDirectory = nil;
    
    if ([possibleURLs count] >= 1) {
        // Use the first directory (if multiple are returned)
        appSupportDir = [possibleURLs objectAtIndex:0];
    }
    
    // If a valid app support directory exists, add the
    // app's bundle ID to it to specify the final directory.
    if (appSupportDir) {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
    }
    
    return appDirectory;
}


- (NSString*) pathToSavedDeviceID{
    NSURL *applicationSupportURL = [self applicationDataDirectory];
    
    if (! [[NSFileManager defaultManager] fileExistsAtPath:[applicationSupportURL path]]){
        
        NSError *error = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:[applicationSupportURL path]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        
        if (error){
            NSLog(@"error creating app support dir: %@", error);
        }
        
    }
    NSString *path = [[applicationSupportURL path] stringByAppendingPathComponent:@"deviceID.plist"];
    
    return path;
}

- (BOOL) CheckDeviceID{
    
    NSString *path = [self pathToSavedDeviceID];
    NSLog(@"CheckDeviceID: %@", path);
    
    
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


- (void) loadDeviceID{
    
    NSString *path = [self pathToSavedDeviceID];
    NSLog(@"LoadDeviceID: %@", path);
    
    self.device_id = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

@end
