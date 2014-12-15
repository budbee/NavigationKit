//
//  NKViewController.h
//  NavigationKit
//
//  Created by Axel Moller on 12/11/2014.
//  Copyright (c) 2014 Axel Moller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import <NavigationKit/NavigationKit.h>

@interface NKViewController : UIViewController <UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, NavigationKitDelegate>

@property (nonatomic, strong) CLLocationManager     *locationManager;
@property (nonatomic, strong) NavigationKit         *navigationKit;

@property (nonatomic, weak) IBOutlet MKMapView      *mapView;

@property (nonatomic, weak) IBOutlet UIView         *addressInputView;
@property (nonatomic, weak) IBOutlet UITextField    *sourceTextField;
@property (nonatomic, weak) IBOutlet UITextField    *destinationTextField;

@property (nonatomic, weak) IBOutlet UIImageView    *maneuverImageView;
@property (nonatomic, weak) IBOutlet UILabel        *distanceLabel;
@property (nonatomic, weak) IBOutlet UILabel        *instructionLabel;
@property (nonatomic, weak) IBOutlet UIButton       *cancelButton;

- (IBAction)cancelNavigation:(id)sender;

@end
