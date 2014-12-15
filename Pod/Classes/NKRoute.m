//
//  NKRoute.m
//  Pods
//
//  Created by Axel Möller on 11/12/14.
//  Copyright (c) 2014 Sendus Sverige AB. All rights reserved.
//

#import "NKRoute.h"
#import "NKRouteStep.h"

@implementation NKRoute

- (id)initWithGoogleMapsRoute:(NSDictionary *)route {
    self = [super init];
    
    if(self && route) {
        
        // Decode the Path and convert coordinates to MKPolyline
        NSString *encodedPolyline = [[route valueForKey:@"overview_polyline"] valueForKey:@"points"];
        self.path = [GMSPath pathFromEncodedPath:encodedPolyline];
        
        CLLocationCoordinate2D *coordinates = calloc([self.path count], sizeof(CLLocationCoordinate2D));
        
        for(int i = 0; i < [self.path count]; i++) {
            coordinates[i] = [self.path coordinateAtIndex:i];
        }
        
        self.polyline = [MKPolyline polylineWithCoordinates:coordinates count:[self.path count]];
        
        free(coordinates);
        
        // Find all steps and convert to NKRouteStep's
        NSDictionary *legs = [[route valueForKey:@"legs"] firstObject];
        NSArray *steps =  [legs objectForKey:@"steps"];
        
        NSMutableArray *routeSteps = [[NSMutableArray alloc] init];
        
        for(NSDictionary *step in steps) {
            NKRouteStep *routeStep = [[NKRouteStep alloc] initWithGoogleMapsStep:step];
            [routeSteps addObject:routeStep];
        }
        
        self.steps = routeSteps;
        
        // Find expectedTravelTime
        self.expectedTravelTime = [[[legs valueForKey:@"duration"] valueForKey:@"value"] doubleValue];
    }
    
    return self;
}

- (id)initWithMKRoute:(MKRoute *)route {
    self = [super init];
    
    if(self && route) {
        
        // Convert Polyline coordinates to GMSPath
        GMSMutablePath *path = [[GMSMutablePath alloc] init];
        for(MKRouteStep *routeStep in [route steps]) {
            
            NSInteger stepPoints = routeStep.polyline.pointCount;
            CLLocationCoordinate2D *coordinates = malloc(stepPoints * sizeof(CLLocationCoordinate2D));
            [routeStep.polyline getCoordinates:coordinates range:NSMakeRange(0, stepPoints)];
            
            for(int i = 0; i < stepPoints; i++) {
                [path addCoordinate:coordinates[i]];
            }
        }
        
        self.path = path;
        
        // Save polyline
        self.polyline = [route polyline];
        
        // Convert array of MKRouteStep's to NKRouteStep's
        NSMutableArray *routeSteps = [[NSMutableArray alloc] init];
        
        for(MKRouteStep *step in [route steps]) {
            NKRouteStep *routeStep = [[NKRouteStep alloc] initWithMKRouteStep:step];
            [routeSteps addObject:routeStep];
        }
        
        self.steps = routeSteps;
        
        // Save expectedTravelTime
        self.expectedTravelTime = [route expectedTravelTime];
    }
    
    return self;
}

@end
