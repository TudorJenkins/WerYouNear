//
//  WEVViewController.h
//  WerYooNear
//
//  Created by Tudor Jenkins on 29/11/2012.
//  Copyright (c) 2012 WideEyedVision. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "WEVTwitterUsersNearBy.h"

@interface WEVViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, WEVTwitterUsersNearByDelegate>
{
    CLLocationManager *locationManager;
}
@property(nonatomic) IBOutlet UITableView* tweetersTableView;
@property(nonatomic) IBOutlet UISegmentedControl* tweetersSortSwitch;
@property(nonatomic, strong) NSMutableArray *statuses;
@property(nonatomic) IBOutlet UILabel* rangeLabel;


@end
