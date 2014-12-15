//
//  NavigationKit.m
//  Pods
//
//  Created by Axel Möller on 11/12/14.
//  Copyright (c) 2014 Sendus Sverige AB. All rights reserved.
//

#import "NavigationKit.h"

#define NavigationKitErrorDomain @"com.navigationkit"

@interface NavigationKit ()

// Initializing
@property (nonatomic) CLLocationCoordinate2D source;
@property (nonatomic) CLLocationCoordinate2D destination;
@property (nonatomic) MKDirectionsTransportType transportType;
@property (nonatomic) NavigationKitDirectionsService directionsService;

// Objects for calculated route
@property (nonatomic, strong) NKRoute *route;

// Information to keep track of progress
@property (nonatomic) BOOL navigating;
@property (nonatomic) NSInteger currentStepInRoute;
@property (nonatomic) CLLocationDistance distanceToEndOfPath;
@property (nonatomic, strong) NSMutableArray *stepNotifications;

@end

@implementation NavigationKit
@synthesize delegate;

- (id)initWithSource:(CLLocationCoordinate2D)source destination:(CLLocationCoordinate2D)destination transportType:(MKDirectionsTransportType)transportType directionsService:(NavigationKitDirectionsService)directionsService {
    self = [super init];
    
    if(self) {
        _source = source;
        _destination = destination;
        _transportType = transportType;
        _directionsService = directionsService;
        _recalculatingTolerance = -1;
        _cameraAltitude = -1;
    }
    
    return self;
}

- (void)calculateDirections {
    _navigating = NO;
    _route = nil;
    _currentStepInRoute = 0;
    _distanceToEndOfPath = 0;
    _stepNotifications = [[NSMutableArray alloc] init];
    
    switch (_directionsService) {
        case NavigationKitDirectionsServiceAppleMaps:
            [self calculateDirectionsAppleMaps];
            break;
        case NavigationKitDirectionsServiceGoogleMaps:
            [self calculateDirectionsGoogleMaps];
            break;
        default:
        {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Invalid Directions Service", nil)
                                       };
            
            if([delegate respondsToSelector:@selector(navigationKitError:)])
                [delegate navigationKitError:[NSError errorWithDomain:NavigationKitErrorDomain code:-1 userInfo:userInfo]];
            break;
        }
    }
}

- (void)startNavigation {
    _navigating = YES;
    if([delegate respondsToSelector:@selector(navigationKitStartedNavigation)])
        [delegate navigationKitStartedNavigation];
    
    // This might be a temporary fix, but for now, notify the delegate that we entered step "0"
    if([delegate respondsToSelector:@selector(navigationKitEnteredRouteStep:nextStep:)])
        [delegate navigationKitEnteredRouteStep:[_route.steps objectAtIndex:0] nextStep:[_route.steps objectAtIndex:1]];
}

- (void)stopNavigation {
    _navigating = NO;
    if([delegate respondsToSelector:@selector(navigationKitStoppedNavigation)])
        [delegate navigationKitStoppedNavigation];
}

- (void)recalculateNavigation {
    if([delegate respondsToSelector:@selector(navigationKitStartedRecalculation)])
        [delegate navigationKitStartedRecalculation];
    
    [self stopNavigation];
    [self calculateDirections];
    [self startNavigation];
}

- (BOOL)isNavigating {
    return _navigating;
}

- (void)calculateActionForLocation:(CLLocation *)location {
    
    // If Turn-by-Turn navigation is not enabled, don't perform any calculations
    if(!_navigating || location == nil || _route == nil)
        return;
    
    // Calculate wether the user is anywhere on the path returned from the directions service (i.e. on route)
    // The default tolerance is 50m
    // Recalculate navigation if user is off path
    BOOL userOnPath = GMSGeometryIsLocationOnPathTolerance([location coordinate], _route.path, YES, _recalculatingTolerance == -1 ? 50 : _recalculatingTolerance);
    if(!userOnPath) {
        // Set source coordinate to the latest location
        _source = [location coordinate];
        return [self recalculateNavigation];
    }
    
    // Calculate which step we are on the path
    // Initially ignore steps that we have already "seen", but if a step was not found then, iterate through all steps in route
    int currentStep = [self stepForLocation:location initialOffset:(int)_currentStepInRoute];
    
    // We are on step 'currentStep', but we want to animate and display information about the next step
    int nextStep = [_route steps].count > currentStep ? currentStep+1 : currentStep;
    
    // We can not currently find which step we are on
    if(currentStep == INT_MAX)
        return;
    
    NKRouteStep *currentRouteStep = [_route.steps objectAtIndex:currentStep];
    NKRouteStep *nextRouteStep = [_route.steps objectAtIndex:nextStep];
    
    // Calculate the driving distance to the end of the current path
    if([delegate respondsToSelector:@selector(navigationKitCalculatedDistanceToEndOfPath:)]) {
        _distanceToEndOfPath = [self distanceToEndOfPath:[currentRouteStep path] location:location];
        [delegate navigationKitCalculatedDistanceToEndOfPath:_distanceToEndOfPath];
    }
    
    // Set the global variable 'currentStepInRoute' to 'currentStep' if updated
    // and notify delegate that text and voice instructions should be updated
    if(currentStep != _currentStepInRoute) {
        _currentStepInRoute = currentStep;
        
        // Notify delegate that we entered a new step
        if([delegate respondsToSelector:@selector(navigationKitEnteredRouteStep:nextStep:)])
            [delegate navigationKitEnteredRouteStep:currentRouteStep nextStep:nextRouteStep];
        
        // Notify delegate to notify the user that we have entered a step (e.g. Speech Synthesizing)
        if([delegate respondsToSelector:@selector(navigationKitCalculatedNotificationForStep:inDistance:)]) {
            [delegate navigationKitCalculatedNotificationForStep:nextRouteStep inDistance:_distanceToEndOfPath];
            // If the distance to the next step is less than 100m, don't repeat this message
            // Messages are repeated when the user comes to the end of the road (see below)
            if(_distanceToEndOfPath < 100)
                [_stepNotifications addObject:nextRouteStep];
        }
    }
    
    // Speak instructions to the user if we are getting close to the end of the current step
    // Do not speak instructions of already considered spoken
    // It is considered close if:
    // Distance to end of path is less than or equal to 200m AND
    // Total distance of path is more than or equal to 1000m AND
    // OR if
    // Distance to end of path is less than or equal to 50m
    if([_stepNotifications indexOfObject:nextRouteStep] == NSNotFound) {
        if(_distanceToEndOfPath <= 200.0 && currentRouteStep.distance >= 1000.0) {
            
            if([delegate respondsToSelector:@selector(navigationKitCalculatedNotificationForStep:inDistance:)])
                [delegate navigationKitCalculatedNotificationForStep:nextRouteStep inDistance:_distanceToEndOfPath];
            [_stepNotifications addObject:nextRouteStep];
            
        } else if(_distanceToEndOfPath <= 50.0) {
            
            if([delegate respondsToSelector:@selector(navigationKitCalculatedNotificationForStep:inDistance:)])
                [delegate navigationKitCalculatedNotificationForStep:nextRouteStep inDistance:_distanceToEndOfPath];
            [_stepNotifications addObject:nextRouteStep];
            
        }
    }
    
    // Calculate the camera angle based on current step, heading and user settings
    if([delegate respondsToSelector:@selector(navigationKitCalculatedCamera:)]) {
        MKMapCamera *camera = nil;
        if(_currentStepInRoute == 0)
            camera = [self defaultCamera:location];
        else
            camera = [self cameraForStep:currentRouteStep location:location];
        
        if(camera)
            [delegate navigationKitCalculatedCamera:camera];
    }
}

#pragma mark - The inner workings (Math, Algorithms, Easy)

- (void)calculateDirectionsGoogleMaps {
    
    NSString *mode = @"driving";
    if(_transportType == MKDirectionsTransportTypeWalking)
        mode = @"walking";
    
    NSString *requestURL = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=true&mode=%@&language=%@",
                            _source.latitude,
                            _source.longitude,
                            _destination.latitude,
                            _destination.longitude,
                            mode,
                            [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
    
    NSURL *url = [NSURL URLWithString:[requestURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSError *error = nil;
        
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(error) {
            if([delegate respondsToSelector:@selector(navigationKitError:)])
                [delegate navigationKitError:error];
            return;
        }
        
        NSArray *routes = [result objectForKey:@"routes"];
        if(!routes) {
            if([delegate respondsToSelector:@selector(navigationKitError:)]) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Could not find any routes for specified locations", nil)
                                           };
                [delegate navigationKitError:[NSError errorWithDomain:NavigationKitErrorDomain code:-2 userInfo:userInfo]];
            }
            return;
        }
        
        NSDictionary *route = [routes firstObject];
        if(!route) {
            if([delegate respondsToSelector:@selector(navigationKitError:)]) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                           NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Could not find any routes for specified locations", nil)
                                           };
                [delegate navigationKitError:[NSError errorWithDomain:NavigationKitErrorDomain code:-2 userInfo:userInfo]];
            }
            return;
        }
        
        _route = [[NKRoute alloc] initWithGoogleMapsRoute:route];
        
        if([delegate respondsToSelector:@selector(navigationKitCalculatedRoute:)])
            [delegate navigationKitCalculatedRoute:_route];
    }];
}

- (void)calculateDirectionsAppleMaps {
    
    MKDirectionsRequest *directionsRequest = [[MKDirectionsRequest alloc] init];
    
    MKPlacemark *source = [[MKPlacemark alloc] initWithCoordinate:_source addressDictionary:nil];
    MKPlacemark *destination = [[MKPlacemark alloc] initWithCoordinate:_destination addressDictionary:nil];
    
    [directionsRequest setSource:[[MKMapItem alloc] initWithPlacemark:source]];
    [directionsRequest setDestination:[[MKMapItem alloc] initWithPlacemark:destination]];
    directionsRequest.transportType = _transportType;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if(error) {
            if([delegate respondsToSelector:@selector(navigationKitError:)])
                [delegate navigationKitError:error];
            return;
        }
        
        _route = [[NKRoute alloc] initWithMKRoute:response.routes.firstObject];
        
        if([delegate respondsToSelector:@selector(navigationKitCalculatedRoute:)])
            [delegate navigationKitCalculatedRoute:_route];
    }];
}

// Generate a CLLocation from a CLLocationCoordinate2D
- (CLLocation *)locationFromCoordinate:(CLLocationCoordinate2D)coordinate {
    return [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
}

// Figure out what step of the route a location is on
- (int)stepForLocation:(CLLocation *)location initialOffset:(int)initialOffset {
    
    int step = INT_MAX;
    
    for(int i = initialOffset; i < _route.steps.count; i++) {
        NKRouteStep *routeStep = [_route.steps objectAtIndex:i];
        if(GMSGeometryIsLocationOnPathTolerance([location coordinate], [routeStep path], YES, 15)) {
            step = i;
            break;
        }
    }
    
    if(step != INT_MAX)
        return step;
    
    for(NKRouteStep *routeStep in _route.steps) {
        if(GMSGeometryIsLocationOnPathTolerance([location coordinate], [routeStep path], YES, 15)) {
            step = (int)[_route.steps indexOfObject:routeStep];
            break;
        }
    }
    
    return step;
}

// Calculate the distance (meters) from a location to the last point in a route step
- (CLLocationDistance)distanceToEndOfPath:(GMSPath *)path location:(CLLocation *)location {
    
    CLLocationDistance totalDistance = 0.0;
    
    // If it's a straight road, get the distance between me and the last point
    if([path count] == 2)
        return [location distanceFromLocation:[self locationFromCoordinate:[path coordinateAtIndex:1]]];
    
    // Find the closest point
    CLLocationDistance smallestDistance = INT_MAX;
    int closestPoint = INT_MAX;
    
    for(int i = 0; i < [path count]; i++) {
        CLLocationDistance distance = [[self locationFromCoordinate:[path coordinateAtIndex:i]] distanceFromLocation:location];
        if(distance < smallestDistance) {
            smallestDistance = distance;
            closestPoint = i;
        }
    }
    
    // Find the total distance from the closest point to the last point
    if(closestPoint == [path count])
        return smallestDistance;
    
    for(int i = closestPoint; i < [path count]-1; i++) {
        CLLocationDistance distance = [[self locationFromCoordinate:[path coordinateAtIndex:i]] distanceFromLocation:[self locationFromCoordinate:[path coordinateAtIndex:i+1]]];
        totalDistance += distance;
    }
    
    return totalDistance;
}

- (BOOL)string:(NSString *)string findSubstring:(NSString *)substring {
    return [string rangeOfString:[substring lowercaseString]].location != NSNotFound;
}

// The Default camera (for step 0, where we don't really have a heading yet)
- (MKMapCamera *)defaultCamera:(CLLocation *)location {
    return [MKMapCamera cameraLookingAtCenterCoordinate:[location coordinate] fromEyeCoordinate:[location coordinate] eyeAltitude:_cameraAltitude == -1 ? 500 : _cameraAltitude];
}

// Calculate the camera based on the users settings
- (MKMapCamera *)cameraForStep:(NKRouteStep *)step location:(CLLocation *)location {
    
    // Find the two closest points in step based on current location
    int i, first, second;
    first = second = INT_MAX;
    CLLocationDistance firstDistance, secondDistance;
    firstDistance = secondDistance = INT_MAX;
    
    for(i = 0; i < [step.path count]; i++) {
        CLLocationDistance distance = [[self locationFromCoordinate:[step.path coordinateAtIndex:i]] distanceFromLocation:location];
        
        if(distance < firstDistance) {
            second = first;
            first = i;
            secondDistance = firstDistance;
            firstDistance = distance;
        }
        
        else if(distance < secondDistance && distance != first) {
            second = i;
            secondDistance = distance;
        }
    }
    
    // return null if we failed to find locations
    if(first == INT_MAX || second == INT_MAX)
        return nil;
    
    // Sort it so we calculate heading based on points in order, regardless of which one is closest
    int firstOccurance = first < second ? first : second;
    int secondOccurance = first < second ? second : first;
    
    // Get heading
    CLLocationDirection heading = GMSGeometryHeading([step.path coordinateAtIndex:firstOccurance], [step.path coordinateAtIndex:secondOccurance]);
    
    CLLocationCoordinate2D coordinateWithOffset = [self coordinate:[location coordinate] atDistance:200 bearing:heading];
    
    MKMapCamera *newCamera = [MKMapCamera camera];
    
    [newCamera setCenterCoordinate:coordinateWithOffset];
    [newCamera setPitch:60];
    [newCamera setHeading:heading];
    [newCamera setAltitude:_cameraAltitude == -1 ? 500 : _cameraAltitude];
    
    return newCamera;
}

- (double)radiansFromDegrees:(double)degrees {
    return degrees * (M_PI / 180.0);
}

- (double)degreesFromRadians:(double)radians {
    return radians * (180.0 / M_PI);
}

// Calculate a CLLocationCoordinate2D at n meters ahead of a location with bearing
- (CLLocationCoordinate2D)coordinate:(CLLocationCoordinate2D)fromCoordinate atDistance:(double)distance bearing:(double)bearing {
    
    double distanceRadians = (distance / 1000) / 6371.0; // 6371 is the earths radius in km
    double bearingRadians = [self radiansFromDegrees:bearing];
    double fromLatitudeRadians = [self radiansFromDegrees:fromCoordinate.latitude];
    double fromLongitudeRadians = [self radiansFromDegrees:fromCoordinate.longitude];
    
    double toLatitudeRadians = asin(sin(fromLatitudeRadians) * cos(distanceRadians) + cos(fromLatitudeRadians) * sin(distanceRadians) * cos(bearingRadians));
    double toLongitudeRadians = fromLongitudeRadians + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatitudeRadians), cos(distanceRadians) - sin(fromLatitudeRadians) * sin(toLatitudeRadians));
    
    // Adjust toLongitudeRadians to be in the range -180 - +180
    toLongitudeRadians = fmod((toLongitudeRadians + 3 * M_PI), (2 * M_PI)) - M_PI;
    
    CLLocationCoordinate2D toCoordinate;
    toCoordinate.latitude = [self degreesFromRadians:toLatitudeRadians];
    toCoordinate.longitude = [self degreesFromRadians:toLongitudeRadians];
    
    return toCoordinate;
}

@end