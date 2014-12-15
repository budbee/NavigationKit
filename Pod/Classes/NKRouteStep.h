//
//  NKRouteStep.h
//  Pods
//
//  Created by Axel Möller on 11/12/14.
//  Copyright (c) 2014 Sendus Sverige AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>

typedef NS_ENUM(NSInteger, NKRouteStepManeuver) {
    NKRouteStepManeuverUnknown,
    NKRouteStepManeuverTurnSharpLeft,
    NKRouteStepManeuverUturnRight,
    NKRouteStepManeuverTurnSlightRight,
    NKRouteStepManeuverMerge,
    NKRouteStepManeuverRoundaboutLeft,
    NKRouteStepManeuverRoundaboutRight,
    NKRouteStepManeuverUturnLeft,
    NKRouteStepManeuverTurnSlightLeft,
    NKRouteStepManeuverTurnLeft,
    NKRouteStepManeuverRampRight,
    NKRouteStepManeuverTurnRight,
    NKRouteStepManeuverForkRight,
    NKRouteStepManeuverStraight,
    NKRouteStepManeuverForkLeft,
    NKRouteStepManeuverFerryTrain,
    NKRouteStepManeuverTurnSharpRight,
    NKRouteStepManeuverRampLeft,
    NKRouteStepManeuverFerry,
    NKRouteStepManeuverKeepLeft,
    NKRouteStepManeuverKeepRight
};

@interface NKRouteStep : NSObject

@property (nonatomic, strong) GMSPath *path;
@property (nonatomic, strong) MKPolyline *polyline;
@property (nonatomic, strong) NSString *instructions;
@property (nonatomic, strong) NSString *notice;
@property (nonatomic) CLLocationDistance distance;
@property (nonatomic) MKDirectionsTransportType transportType;
@property (nonatomic) NKRouteStepManeuver maneuver;

- (id)initWithGoogleMapsStep:(NSDictionary *)step;
- (id)initWithMKRouteStep:(MKRouteStep *)step;

@end