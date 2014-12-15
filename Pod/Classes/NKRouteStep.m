//
//  NKRouteStep.m
//  Pods
//
//  Created by Axel Möller on 11/12/14.
//  Copyright (c) 2014 Sendus Sverige AB. All rights reserved.
//

#import "NKRouteStep.h"

@implementation NKRouteStep

- (id)initWithGoogleMapsStep:(NSDictionary *)step {
    self = [super init];
    
    if(self) {
        NSString *encodedPolyline = [[step valueForKey:@"polyline"] valueForKey:@"points"];
        
        self.path = [GMSPath pathFromEncodedPath:encodedPolyline];
        
        CLLocationCoordinate2D *coordinates = calloc([self.path count], sizeof(CLLocationCoordinate2D));
        
        for(int i = 0; i < [self.path count]; i++) {
            coordinates[i] = [self.path coordinateAtIndex:i];
        }
        
        self.polyline = [MKPolyline polylineWithCoordinates:coordinates count:[self.path count]];
        
        free(coordinates);
        
        self.instructions = [step valueForKey:@"html_instructions"];
        self.distance = [[[step valueForKey:@"distance"] valueForKey:@"value"] doubleValue];
        if([[step valueForKey:@"travel_mode"] isEqualToString:@"DRIVING"])
            self.transportType = MKDirectionsTransportTypeAutomobile;
        
        self.maneuver = [self maneuver:[step valueForKey:@"maneuver"]];
    }
    
    return self;
}

- (id)initWithMKRouteStep:(MKRouteStep *)step {
    self = [super init];
    
    if(self && step) {
        
        // Convert polyline to GMSPath
        NSInteger stepPoints = step.polyline.pointCount;
        CLLocationCoordinate2D *coordinates = malloc(stepPoints * sizeof(CLLocationCoordinate2D));
        [step.polyline getCoordinates:coordinates range:NSMakeRange(0, stepPoints)];
        
        GMSMutablePath *stepGMSPath = [[GMSMutablePath alloc] init];
        for(int i = 0; i < stepPoints; i++) {
            [stepGMSPath addCoordinate:coordinates[i]];
        }
        self.path = stepGMSPath;
        free(coordinates);
        
        // Save polyline
        self.polyline = [step polyline];
        
        self.instructions = [step instructions];
        self.distance = [step distance];
        
        // Apple directions does not contain maneuvers
        // and parsing the natural text is a hassle, because Apple returns in the locale of the phone
        // If you can solve this in another way, please fork and create a pull request
        self.maneuver = NKRouteStepManeuverUnknown;
    }
    
    return self;
}

- (NKRouteStepManeuver)maneuver:(NSString *)googleManeuver {
    
    if(!googleManeuver)
        return NKRouteStepManeuverUnknown;
    
    if([googleManeuver isEqualToString:@"turn-sharp-left"])
        return NKRouteStepManeuverTurnSharpLeft;
    
    if([googleManeuver isEqualToString:@"uturn-right"])
        return NKRouteStepManeuverUturnRight;
    
    if([googleManeuver isEqualToString:@"turn-slight-right"])
        return NKRouteStepManeuverTurnSlightRight;
    
    if([googleManeuver isEqualToString:@"merge"])
        return NKRouteStepManeuverMerge;
    
    if([googleManeuver isEqualToString:@"roundabout-left"])
        return NKRouteStepManeuverRoundaboutLeft;
    
    if([googleManeuver isEqualToString:@"roundabout-right"])
        return NKRouteStepManeuverRoundaboutRight;
    
    if([googleManeuver isEqualToString:@"uturn-left"])
        return NKRouteStepManeuverUturnLeft;
    
    if([googleManeuver isEqualToString:@"turn-slight-left"])
        return NKRouteStepManeuverTurnSlightLeft;
    
    if([googleManeuver isEqualToString:@"turn-left"])
        return NKRouteStepManeuverTurnLeft;
    
    if([googleManeuver isEqualToString:@"ramp-right"])
        return NKRouteStepManeuverRampRight;
    
    if([googleManeuver isEqualToString:@"turn-right"])
        return NKRouteStepManeuverTurnRight;
    
    if([googleManeuver isEqualToString:@"fork-right"])
        return NKRouteStepManeuverForkRight;
    
    if([googleManeuver isEqualToString:@"straight"])
        return NKRouteStepManeuverStraight;
    
    if([googleManeuver isEqualToString:@"fork-left"])
        return NKRouteStepManeuverForkLeft;
    
    if([googleManeuver isEqualToString:@"ferry-train"])
        return NKRouteStepManeuverFerryTrain;
    
    if([googleManeuver isEqualToString:@"turn-sharp-right"])
        return NKRouteStepManeuverTurnSharpRight;
    
    if([googleManeuver isEqualToString:@"ramp-left"])
        return NKRouteStepManeuverRampLeft;
    
    if([googleManeuver isEqualToString:@"ferry"])
        return NKRouteStepManeuverFerry;
    
    if([googleManeuver isEqualToString:@"keep-left"])
        return NKRouteStepManeuverKeepLeft;
    
    if([googleManeuver isEqualToString:@"keep-right"])
        return NKRouteStepManeuverKeepRight;
    
    return NKRouteStepManeuverUnknown;
}

@end