//
//  WEVTwitterUsersNearBy.m
//  WerYooNear
//
//  Created by Tudor Jenkins on 29/11/2012.
//  Copyright (c) 2012 WideEyedVision. All rights reserved.
//
#define GPS_UPDATING_DISTANCE   250
#define TWEET_SEARCH_RANGE_KM      12.0

#define TWITTER_SEARCH_ENDPOINT @"https://api.twitter.com/1.1/search/tweets.json"
#define TWITTER_REVERSE_GEOCODE_ENDPOINT @"http://api.twitter.com/1.1/geo/reverse_geocode.json"


#import "WEVTwitterUsersNearBy.h"
#import "Twitter/TWRequest.h"
#import "Accounts/ACAccountStore.h"
#import "Accounts/ACAccountType.h"


@implementation WEVTwitterUsersNearBy{
    CLLocationManager *locationManager;
    ACAccountStore *store_;
    ACAccountType *twitterAccountType_;
}


@synthesize delegate=delegate_;
@synthesize searchRangeInKm=searchRangeInKm_;

- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        
        self.delegate = delegate;
        searchRangeInKm_ = TWEET_SEARCH_RANGE_KM;
        //  First, we need to obtain the account instance for the user's Twitter account
        store_ = [[ACAccountStore alloc] init];
        twitterAccountType_ = [store_ accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        // setup location tracking  ***** this is GPS battery heavy so think about this a bit more
        // but I guess that users will be in the app just to use the GPS!
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = GPS_UPDATING_DISTANCE;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
        
        // In real app, need to manage locationManager so that it is switched off once it returns what we need.
    }
    return self;
}

-(void)updateLocation
{
    if(locationManager != nil)
    {
        [locationManager startUpdatingLocation];
         // In real app, need to manage locationManager so that it is switched off once it returns what we need.
    }
}


#pragma mark location manager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    [locationManager stopUpdatingLocation];  // for now, this is just a single shot - but typically would be continuous based on distanceFilter
    
    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    
// set off both searches
    [self handleTwitterRequestWithLat:newLocation.coordinate.latitude withLong:newLocation.coordinate.longitude];
    [self handleTwitterReverseGeoWithLat:newLocation.coordinate.latitude withLong:newLocation.coordinate.longitude];
    
}

-(void)handleTwitterRequestWithLat:(float)latitude withLong:(float)longitude
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSString stringWithFormat:@"%f,%f,%fkm",latitude,longitude,searchRangeInKm_] forKey:@"geocode"];
    [params setObject:@"" forKey:@"q"];  // ie empty search.... get everything in area
    [params setObject:@"30" forKey:@"count"];  // THIS WILL BE SET TO MAX ie 100 once app is fully tested (dont go over quota when testing)
    
    [self handleTwitterSearchRequestWithParams:params];
}
-(void)handleTwitterRequestWithPlace:(NSString*)place
{
    NSString* searchTerm = [[NSString stringWithFormat:@"place:%@", place] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:searchTerm forKey:@"q"];  
    [params setObject:@"30" forKey:@"count"];  // THIS WILL BE SET TO MAX ie 100 once app is fully tested (dont go over quota when testing)
   
    [self handleTwitterSearchRequestWithParams:params];
}

-(void)handleTwitterSearchRequestWithParams:(NSDictionary*)params
{
    //  Request permission from the user to access the available Twitter accounts
    [store_ requestAccessToAccountsWithType:twitterAccountType_
                      withCompletionHandler:^(BOOL granted, NSError *error)
     {
         if (!granted)
         {
             // The user rejected your request
             NSLog(@"User rejected access to the account. REPLACE THIS WITH A UIAlert");
         }
         else
         {
             // Grab the available accounts
             NSArray *twitterAccounts = [store_ accountsWithAccountType:twitterAccountType_];
             
             if ([twitterAccounts count] > 0)
             {
                 // Use the first account for simplicity
                 ACAccount *account = [twitterAccounts objectAtIndex:0];
                 // Now make an authenticated request to our endpoint
                 //  The endpoint that we wish to call
                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
                 //  Build the request with our parameter
                 TWRequest *request = [[TWRequest alloc] initWithURL:url
                                                          parameters:params
                                                       requestMethod:TWRequestMethodGET];
                 // Attach the account object to this request
                 [request setAccount:account];
                 
                 [request performRequestWithHandler: ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                  {
                      if (!responseData)
                      {
                          // inspect the contents of error
                          NSLog(@"%@", error);
                      }
                      else
                      {
                          NSError *jsonError;
                          
                          /* NSArray *timeline = */
                          NSDictionary *timeline = [NSJSONSerialization JSONObjectWithData:responseData
                                                                                   options:NSJSONReadingMutableLeaves
                                                                                     error:&jsonError];
                          if (timeline)
                          {
                              // at this point, we have an object that we can parse
                              NSLog(@"number of items is:%d",[timeline count]);
                              int numberOfStatus = [[timeline objectForKey:@"statuses"] count];
                              NSLog(@"number of statuses are %d",numberOfStatus);
                              
                              // on main thread update the tableview source
                              dispatch_async(dispatch_get_main_queue(), ^(void){
                                  [self updateFeed:[timeline objectForKey:@"statuses"]];
                              });
                          }
                          else
                          {
                              // inspect the contents of jsonError
                              NSLog(@"%@", jsonError);
                          }
                      }
                  }];
             } // if ([twitterAccounts count] > 0)
         } // if (granted) 
     }];
}



-(void)updateFeed:(id)feedData
{    
    // handle delegate
    if(self.delegate && [self.delegate respondsToSelector:@selector(twitterUsersReceived:)])
    {
        [self.delegate twitterUsersReceived:(NSArray *)feedData];
    }
}



-(void)handleTwitterReverseGeoWithLat:(float)latitude withLong:(float)longitude
{
    //  Request permission from the user to access the available Twitter accounts
    [store_ requestAccessToAccountsWithType:twitterAccountType_ withCompletionHandler:^(BOOL granted, NSError *error)
    {
        if (!granted)
        {
            // The user rejected your request
            NSLog(@"User rejected access to the account. REPLACE THIS WITH A UIAlert");
        }
        else
        {
            // Grab the available accounts
            NSArray *twitterAccounts = [store_ accountsWithAccountType:twitterAccountType_];
            if ([twitterAccounts count] > 0)
            {
                // Use the first account for simplicity
                ACAccount *account = [twitterAccounts objectAtIndex:0];
                 
                // Now make an authenticated request to our endpoint
                NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                [params setObject:[NSString stringWithFormat:@"%f",latitude] forKey:@"lat"];
                [params setObject:[NSString stringWithFormat:@"%f",longitude] forKey:@"long"];
                [params setObject:[NSString stringWithFormat:@"%f",searchRangeInKm_*1000] forKey:@"accuracy"];  // ie 2000m
                [params setObject:@"poi" forKey:@"granularity"];  // finest level of detail..
                 
                //  The endpoint that we wish to call
                NSURL *url = [NSURL URLWithString:TWITTER_REVERSE_GEOCODE_ENDPOINT];
                 
                //  Build the request with our parameter
                TWRequest *request = [[TWRequest alloc] initWithURL:url
                                                         parameters:params
                                                      requestMethod:TWRequestMethodGET];
                 
                // Attach the account object to this request
                [request setAccount:account];
                 
                [request performRequestWithHandler: ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                {
                    if (!responseData)
                    {
                        // inspect the contents of error
                        NSLog(@"%@", error);
                    }
                    else
                    {
                        NSError *jsonError;
                        NSDictionary *timeline = [NSJSONSerialization JSONObjectWithData:responseData
                                                                                 options:NSJSONReadingMutableLeaves
                                                                                   error:&jsonError];
                        if (timeline)
                        {
                            // at this point, we have an object that we can parse
                            NSLog(@"number of items is:%d",[timeline count]);
                            NSDictionary* result = [timeline objectForKey:@"result"];
                            [self processPlaces:[result objectForKey:@"places"]  withLatitude:latitude withLongitude:longitude];
                        }
                        else
                        {
                            // inspect the contents of jsonError
                            NSLog(@"%@", jsonError);
                        }
                    }
                }];
                
            } // if ([twitterAccounts count] > 0)
        } // if (granted)
    }];
}


-(void)processPlaces:(id)feedData withLatitude:(float)myLatitude withLongitude:(float)myLongitude
{
    NSMutableArray* places = [[NSMutableArray alloc] initWithArray:(NSArray*)feedData];
    for(int i=0;i<[places count]; i++)
    {
        NSDictionary *place = [places objectAtIndex:i];
        NSLog(@"%@", [place objectForKey:@"name"]);
        NSArray * coordinates = [[[place objectForKey:@"bounding_box"] objectForKey:@"coordinates"] objectAtIndex:0] ;
        float maximumPossibleDistanceOfTweet = [self getMaximumPossibleDistanceInsidePlace:coordinates  withLatitude:myLatitude withLongitude:myLongitude];
        NSLog(@"maximum distance in to travel in this zone is %f", maximumPossibleDistanceOfTweet);
        
        // now we have the maximum distance we can see if this is acceptable
        if(maximumPossibleDistanceOfTweet <= searchRangeInKm_)
        {
            // acceptable place so request users at this location
            [self handleTwitterRequestWithPlace:[place objectForKey:@"id"]];
        }
    }
    // so we now only have places that fall entirely within search range - time to do a search for tweets from that place
}

// returns distance in km of the greatest distance possible within place from coords
-(float)getMaximumPossibleDistanceInsidePlace:(NSArray *) coordinates  withLatitude:(float)myLatitude withLongitude:(float)myLongitude
{
    float distance = 0.0;  // this is greatest possible value or we are MORE than half way around the world ie coming back other way
    
    // compare every node against every other node . Only need to make comparison once ie a->b  without bothering with b->a
    int totalNodes = [coordinates count];
    for (int node1 = 0; node1< (totalNodes-1);node1++)
    {
        for(int node2 = node1+1; node2 < totalNodes; node2++)
        {
            // we are now comparing 2 different nodes for only time. Look at distance between them and record it if it is greatest
            float node1Long = [[[coordinates objectAtIndex:node1] objectAtIndex:0] floatValue];
            float node1Lat  = [[[coordinates objectAtIndex:node1] objectAtIndex:1] floatValue];
            float node2Long = myLongitude;
            float node2Lat  = myLatitude;
            
            float longDifference    = remainderf(node1Long - node2Long, 180.0); // this takes account of issues on grenwich meridian and IDL
            float latDifference     = remainderf(node1Lat - node2Lat,180.0);
            // now convert to miles
            //  this is an estimate given that we are only dealing with small differences. For longitude distance, assume both at approx same latitude.....
            float scalingFactorForLongitude = ABS(cos(M_PI * ((node1Lat+node2Lat)/2)/180.0 ));
            float latDifferenceKm   = latDifference * 69.0 * 9/5;  // 69miles = 1 degree of latitude      9/5  = miles->km
            float longDifferenceKm  = longDifference * scalingFactorForLongitude * 69.0 * 9/5;
            
            float distanceBetweenNodes = sqrtf(latDifferenceKm*latDifferenceKm + longDifferenceKm*longDifferenceKm);  //pythagoras
            
            if(distanceBetweenNodes > distance)
            {
                distance = distanceBetweenNodes;
            }
        }
    }
    
    return distance;
}


@end
