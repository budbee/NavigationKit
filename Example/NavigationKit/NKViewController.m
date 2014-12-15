//
//  NKViewController.m
//  NavigationKit
//
//  Created by Axel Moller on 12/11/2014.
//  Copyright (c) 2014 Axel Moller. All rights reserved.
//

#import "NKViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface NKViewController ()

@end

@implementation NKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Ask for User location
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager requestWhenInUseAuthorization];
	
    [self.sourceTextField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:self.sourceTextField.placeholder attributes:@{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.6]}]];
    [self.destinationTextField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:self.destinationTextField.placeholder attributes:@{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.6]}]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    if([textField isEqual:self.sourceTextField]) {
        [self.destinationTextField becomeFirstResponder];
        return YES;
    }
    
    if([textField isEqual:self.destinationTextField]) {
        [self navigateFrom:self.sourceTextField.text to:self.destinationTextField.text];
        return YES;
    }
    
    return NO;
}

#pragma - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer *routeLineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
    routeLineRenderer.strokeColor = [UIColor colorWithRed:0.000 green:0.620 blue:0.827 alpha:1];
    routeLineRenderer.lineWidth = 5;
    return routeLineRenderer;
}

#pragma mark - Navigation Methods

- (void)navigateFrom:(NSString *)source to:(NSString *)destination {
    NSLog(@"Looking up driving directions from \"%@\" to \"%@\"", source, destination);
    
    CLPlacemark __block *sourcePlacemark, __block *destinationPlacemark;
    
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder geocodeAddressString:source completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error) {
            NSLog(@"Could not find Source address");
            return;
        }
        
        sourcePlacemark = [placemarks firstObject];
        
        [geoCoder geocodeAddressString:destination completionHandler:^(NSArray *placemarks, NSError *error) {
            if(error) {
                NSLog(@"Could not find Destination address");
                return;
            }
            
            destinationPlacemark = [placemarks firstObject];
            
            NSLog(@"Geocoded address to {%f,%f} - {%f,%f}", [sourcePlacemark location].coordinate.latitude, [sourcePlacemark location].coordinate.longitude, [destinationPlacemark location].coordinate.latitude, [destinationPlacemark location].coordinate.longitude);
            
            self.navigationKit = [[NavigationKit alloc] initWithSource:[sourcePlacemark location].coordinate destination:[destinationPlacemark location].coordinate transportType:MKDirectionsTransportTypeAutomobile directionsService:NavigationKitDirectionsServiceGoogleMaps];
            [self.navigationKit setDelegate:self];
            
            [self.navigationKit calculateDirections];
        }];
    }];
}

- (IBAction)cancelNavigation:(id)sender {
    NSLog(@"Cancel navigation");
    [self.navigationKit stopNavigation];
}

#pragma mark - Helper Methods

// Round up a distance by multiple
- (CLLocationDistance)roundedDistance:(CLLocationDistance)distance multiple:(int)multiple {
    return (multiple - (int)distance % multiple) + distance;
}

- (NSString *)formatDistance:(CLLocationDistance)distance abbreviated:(BOOL)abbreviated {
    
    CLLocationDistance roundedDistance = [self roundedDistance:distance multiple:100];
    
    if(distance < 100)
        roundedDistance = [self roundedDistance:distance multiple:50];
    
    if(distance < 50)
        roundedDistance = [self roundedDistance:distance multiple:10];
    
    if(roundedDistance < 1000)
        return [NSString stringWithFormat:@"%d %@", (int)roundedDistance, abbreviated ? @"m" : @"meters"];
    else
        return [NSString stringWithFormat:@"%.01f %@", roundedDistance/1000, abbreviated ? @"km" : @"kilometers"];
}

- (NSString *)sanitizedHTMLString:(NSString *)string {
    return [[[NSAttributedString alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil] string];
}

- (UIImage *)imageForRouteStepManeuver:(NKRouteStepManeuver)maneuver {
    
    // Default to straight
    UIImage *image = [UIImage imageNamed:@"straight"];;
    
    switch (maneuver) {
        case NKRouteStepManeuverTurnSharpLeft:
            image = [UIImage imageNamed:@"turn-sharp-left"];
            break;
        case NKRouteStepManeuverUturnRight:
            image = [UIImage imageNamed:@"uturn-right"];
            break;
        case NKRouteStepManeuverTurnSlightRight:
            image = [UIImage imageNamed:@"turn-slight-right"];
            break;
        case NKRouteStepManeuverMerge:
            image = [UIImage imageNamed:@"merge"];
            break;
        case NKRouteStepManeuverRoundaboutLeft:
            image = [UIImage imageNamed:@"roundabout-left"];
            break;
        case NKRouteStepManeuverRoundaboutRight:
            image = [UIImage imageNamed:@"roundabout-right"];
            break;
        case NKRouteStepManeuverUturnLeft:
            image = [UIImage imageNamed:@"uturn-left"];
            break;
        case NKRouteStepManeuverTurnSlightLeft:
            image = [UIImage imageNamed:@"turn-slight-left"];
            break;
        case NKRouteStepManeuverTurnLeft:
            image = [UIImage imageNamed:@"turn-left"];
            break;
        case NKRouteStepManeuverRampRight:
            image = [UIImage imageNamed:@"ramp-right"];
            break;
        case NKRouteStepManeuverTurnRight:
            image = [UIImage imageNamed:@"turn-right"];
            break;
        case NKRouteStepManeuverForkRight:
            image = [UIImage imageNamed:@"fork-right"];
            break;
        case NKRouteStepManeuverStraight:
            image = [UIImage imageNamed:@"straight"];
            break;
        case NKRouteStepManeuverForkLeft:
            image = [UIImage imageNamed:@"fork-left"];
            break;
        case NKRouteStepManeuverTurnSharpRight:
            image = [UIImage imageNamed:@"turn-sharp-right"];
            break;
        case NKRouteStepManeuverRampLeft:
            image = [UIImage imageNamed:@"ramp-left"];
            break;
        default:
            break;
    }
    
    return image;
}

#pragma mark - NavigationKitDelegate

- (void)navigationKitError:(NSError *)error {
    NSLog(@"NavigationKit Error: %@", [error localizedDescription]);
}

- (void)navigationKitCalculatedRoute:(NKRoute *)route {
    NSLog(@"NavigationKit Calculated Route with %lu steps", (unsigned long)[route steps].count);
    
    // Start location updates
    [self.locationManager startUpdatingLocation];
    
    // Add Path to map
    [self.mapView addOverlay:[route polyline] level:MKOverlayLevelAboveRoads];
    [self.mapView setVisibleMapRect:[[route polyline] boundingMapRect] edgePadding:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0) animated:YES];
    
    // Hide address input fields
    [UIView animateWithDuration:0.5 animations:^{
        [self.addressInputView setAlpha:0.0];
    }];
    
    // Start navigation
    [self.navigationKit startNavigation];
}

- (void)navigationKitStartedNavigation {
    NSLog(@"NavigationKit Started Navigation");
}

- (void)navigationKitStoppedNavigation {
    NSLog(@"NavigationKit Stopped Navigation");
    
    // Reset UI state
    [self.mapView removeOverlays:[self.mapView overlays]];
    
    [self.instructionLabel setText:nil];
    [self.distanceLabel setText:nil];
    [self.maneuverImageView setImage:nil];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.addressInputView setAlpha:1.0];
    }];
}

- (void)navigationKitStartedRecalculation {
    NSLog(@"NavigationKit Started Recalculating Route");
    
    // Remove overlays
    [self.mapView removeOverlays:[self.mapView overlays]];
}

- (void)navigationKitEnteredRouteStep:(NKRouteStep *)step nextStep:(NKRouteStep *)nextStep {
    NSLog(@"NavigationKit Entered New Step");
    [self.instructionLabel setText:[self sanitizedHTMLString:[nextStep instructions]]];
    
    // Set maneuver icon if available
    [self.maneuverImageView setImage:[self imageForRouteStepManeuver:[nextStep maneuver]]];
}

- (void)navigationKitCalculatedDistanceToEndOfPath:(CLLocationDistance)distance {
    NSString *formattedDistance = [self formatDistance:distance abbreviated:YES];
    [self.distanceLabel setText:formattedDistance];
}

- (void)navigationKitCalculatedNotificationForStep:(NKRouteStep *)step inDistance:(CLLocationDistance)distance {
    NSLog(@"NavigationKit Calculated Notification \"%@\" (in %f meters)", [step instructions], distance);
    
    NSString *message = [NSString stringWithFormat:@"In %@, %@", [self formatDistance:distance abbreviated:NO], [self sanitizedHTMLString:[step instructions]]];
    
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:message];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:[[NSLocale currentLocale] localeIdentifier]];
    [utterance setRate:0.10];
    
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    [speechSynthesizer speakUtterance:utterance];
}

- (void)navigationKitCalculatedCamera:(MKMapCamera *)camera {
    [self.mapView setCamera:camera animated:YES];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations firstObject];
    [self.navigationKit calculateActionForLocation:location];
}

@end
