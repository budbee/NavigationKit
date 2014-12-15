//
//  NKRoute.h
//  Pods
//
//  Created by Axel Möller on 11/12/14.
//  Copyright (c) 2014 Sendus Sverige AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>

@class MKPolyline;
@interface NKRoute : NSObject

@property (nonatomic, strong) GMSPath *path;
@property (nonatomic, strong) MKPolyline *polyline;
@property (nonatomic, strong) NSArray *steps;
@property (nonatomic) NSTimeInterval expectedTravelTime;

- (id)initWithGoogleMapsRoute:(NSDictionary *)route;
- (id)initWithMKRoute:(MKRoute *)route;

@end