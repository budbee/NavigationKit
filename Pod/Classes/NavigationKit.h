//
//  NavigationKit.h
//  Pods
//
//  Created by Axel Möller on 11/12/14.
//  Copyright (c) 2014 Sendus Sverige AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>

#import "NKRoute.h"
#import "NKRouteStep.h"

typedef enum NavigationKitDirectionsService {
    NavigationKitDirectionsServiceAppleMaps,
    NavigationKitDirectionsServiceGoogleMaps
} NavigationKitDirectionsService;

@protocol NavigationKitDelegate <NSObject>

- (void)navigationKitCalculatedRoute:(NKRoute *)route;
- (void)navigationKitError:(NSError *)error;
- (void)navigationKitStartedNavigation;
- (void)navigationKitEnteredRouteStep:(NKRouteStep *)step nextStep:(NKRouteStep *)nextStep;
- (void)navigationKitCalculatedDistanceToEndOfPath:(CLLocationDistance)distance;
- (void)navigationKitCalculatedNotificationForStep:(NKRouteStep *)step inDistance:(CLLocationDistance)distance;
- (void)navigationKitCalculatedCamera:(MKMapCamera *)camera;
- (void)navigationKitStartedRecalculation;
- (void)navigationKitStoppedNavigation;

@end

@interface NavigationKit : NSObject

@property (nonatomic, assign) id<NavigationKitDelegate> delegate;

// User settings
@property (nonatomic, assign) NSInteger recalculatingTolerance;
@property (nonatomic, assign) NSInteger cameraAltitude;

- (id)initWithSource:(CLLocationCoordinate2D)source destination:(CLLocationCoordinate2D)destination transportType:(MKDirectionsTransportType)transportType directionsService:(NavigationKitDirectionsService)directionsService;

- (void)calculateDirections;

- (void)startNavigation;
- (void)stopNavigation;
- (void)recalculateNavigation;

- (BOOL)isNavigating;

- (void)calculateActionForLocation:(CLLocation *)location;

@end