//
//  ViewController.m
//  BeaconAlpha
//
//  Created by Justin Gaussoin on 12/9/13.
//  Copyright (c) 2013 Justin Gaussoin. All rights reserved.
//

#import "ViewController.h"
#import "ESTBeaconManager.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface ViewController () <ESTBeaconManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) ESTBeaconManager* beaconManager;
@property (nonatomic, strong) UIImageView*      positionDot;
@property (nonatomic, strong) ESTBeacon*        selectedBeacon;

@property (nonatomic) float dotMinPos;
@property (nonatomic) float dotRange;



@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

//B9407F30-F5F8-466E-AFF9-25556B57FE6D
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCL];
}


-(void)setupCL
{
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"]; //Change with your iBeacons UUIDs
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"com.MobileTuts.iBeacons"];
    [_locationManager startMonitoringForRegion:_beaconRegion];

    
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"didStartMonitoringForRegion");
    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"didUpdateLocations");
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"didEnterRegion");
    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
}
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"didExitRegion");
    [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
}


-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    //NSLog(@"didRangeBeacons");
    CLBeacon *beacon = [[CLBeacon alloc] init];
    beacon = [beacons lastObject];
    _idLabel.text = beacon.proximityUUID.UUIDString;
    _infoLabel.text = [NSString stringWithFormat:@"raw RSSI: %li", (long)beacon.rssi];
    
    
    if (beacon.proximity == CLProximityUnknown) {
        _normLabel.text = @"Unknown";
    } else if ( beacon.proximity == CLProximityImmediate ) {
        _normLabel.text = @"Immediate";
    } else if ( beacon.proximity == CLProximityNear ) {
        _normLabel.text = @"Near";
    } else if ( beacon.proximity == CLProximityFar ) {
        _normLabel.text = @"Far";
    }
    _siLabel.text = [NSString stringWithFormat:@"Accuracy: %f", beacon.accuracy];
}


-(void)setupEST
{
    /////////////////////////////////////////////////////////////
    // setup Estimote beacon manager
    
    // create manager instance
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    // create sample region object (you can additionaly pass major / minor values)
    ESTBeaconRegion* region = [[ESTBeaconRegion alloc] initRegionWithIdentifier:@"EstimoteSampleRegion"];
    
    // start looking for estimote beacons in region
    // when beacon ranged beaconManager:didRangeBeacons:inRegion: invoked
    [self.beaconManager startRangingBeaconsInRegion:region];
    
    
    /////////////////////////////////////////////////////////////
    // setup Estimote beacon manager
    
    [self setupView];
}

-(void)setupView
{
    /////////////////////////////////////////////////////////////
    // setup background image
    
    CGRect          screenRect          = [[UIScreen mainScreen] bounds];
    CGFloat         screenHeight        = screenRect.size.height;
    UIImageView*    backgroundImage;
    
    backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backgroundBig"]];

    [self.view insertSubview:backgroundImage atIndex:0];
    /////////////////////////////////////////////////////////////
    // setup dot image
    
    self.positionDot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dotImage"]];
    [self.positionDot setCenter:self.view.center];
    [self.positionDot setAlpha:1.];
    
    [self.view addSubview:self.positionDot];
    
    self.dotMinPos = 150;
    self.dotRange = self.view.bounds.size.height  - 220;
}


-(void)beaconManager:(ESTBeaconManager *)manager
     didRangeBeacons:(NSArray *)beacons
            inRegion:(ESTBeaconRegion *)region
{
    if([beacons count] > 0)
    {
        if(!self.selectedBeacon)
        {
            // initially pick closest beacon
            self.selectedBeacon = [beacons objectAtIndex:0];
        }
        else
        {
            for (ESTBeacon* cBeacon in beacons)
            {
                // update beacon it same as selected initially
                if([self.selectedBeacon.major unsignedShortValue] == [cBeacon.major unsignedShortValue] &&
                   [self.selectedBeacon.minor unsignedShortValue] == [cBeacon.minor unsignedShortValue])
                {
                    self.selectedBeacon = cBeacon;
                }
            }
        }
        
        _infoLabel.text = [NSString stringWithFormat:@"RAW Distance RSSI: %li", (long)self.selectedBeacon.rssi];
        
        
        
        // based on observation rssi is not getting bigger then -30
        // so it changes from -30 to -100 so we normalize
        float distFactor = ((float)self.selectedBeacon.rssi + 30) / -70;

        
        _normLabel.text =[NSString stringWithFormat:@"Normal Distance RSSI: %f", distFactor];
        NSLog(@"ID: %@", self.selectedBeacon.proximityUUID.UUIDString);
        
        _idLabel.text = self.selectedBeacon.proximityUUID.UUIDString;
        
        
        // calculate and set new y position
        float newYPos = self.dotMinPos + distFactor * self.dotRange;
        self.positionDot.center = CGPointMake(self.view.bounds.size.width / 2, newYPos);
    }
}





@end
