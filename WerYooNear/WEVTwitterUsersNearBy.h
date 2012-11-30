//
//  WEVTwitterUsersNearBy.h
//  WerYooNear
//
//  Created by Tudor Jenkins on 29/11/2012.
//  Copyright (c) 2012 WideEyedVision. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol WEVTwitterUsersNearByDelegate <NSObject>
@required
-(void)twitterUsersReceived:(NSArray*)users;
@end




@interface WEVTwitterUsersNearBy : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id delegate;
@property (nonatomic) float searchRangeInKm;

-(id)initWithDelegate:(id)delegate;
-(void)updateLocation;

@end
