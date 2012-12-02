//
//  WEVViewController.m
//  WerYooNear
//
//  Created by Tudor Jenkins on 29/11/2012.
//  Copyright (c) 2012 WideEyedVision. All rights reserved.
//
#define GPS_UPDATING_DISTANCE   50

#import "WEVViewController.h"
#import "Twitter/TWRequest.h"
#import "Accounts/ACAccountStore.h"
#import "Accounts/ACAccountType.h"

@interface WEVViewController (){
    WEVTwitterUsersNearBy * twitterUsersNearby;
}

@end

@implementation WEVViewController

@synthesize tweetersSortSwitch;
@synthesize tweetersTableView;
@synthesize rangeLabel=rangeLabel_;

@synthesize statuses=statuses_;


- (void)viewDidLoad
{
    //
    self.statuses = [[NSMutableArray alloc] initWithObjects:nil];  // create an empty array - for tableview before we get response
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // set up the segmented controller
    [tweetersSortSwitch addTarget:self
                         action:@selector(pickSortType:)
               forControlEvents:UIControlEventValueChanged];

    // enable the twitter interactor
    twitterUsersNearby = [[WEVTwitterUsersNearBy alloc] initWithDelegate:self];
    self.rangeLabel.text = [NSString stringWithFormat:@"%.2f km", twitterUsersNearby.searchRangeInKm];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




//Action method executes when user touches the button
- (void) pickSortType:(id)sender{
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    if([segmentedControl selectedSegmentIndex] == 0)
    {
        NSLog(@"segment switched to 0");
    }
    else
    {
        NSLog(@"segment switched to 1");
    }
//	label.text = [segmentedControl titleForSegmentAtIndex: [segmentedControl selectedSegmentIndex]];
}


#pragma mark tableView delegate / source
/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return VENUE_TABLE_CELL_HEIGHT;
}
*/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = [self.statuses count];
    NSLog(@"number of entries for table is: %d",count);
    return count ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StatusTableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone; // stops selected cell from changing appearance
    cell.tag = indexPath.row;
    cell.clipsToBounds = YES;
    
    NSDictionary *tweet = [self.statuses objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",[[tweet objectForKey:@"user"] objectForKey:@"name"]];
    // just for  now, include the id so that we can be sure not two users are present in list
    NSString *detail = [NSString stringWithFormat:@"%@",[[tweet objectForKey:@"user"] objectForKey:@"location"]];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.text = detail;
    return cell;
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark WEVTwitterUsersNearBy Delegate

-(void)twitterUsersReceived:(NSArray*)users
{
// this always adds on account of the asynchronous or dribbly nature of twitter reply
    
    // NEED TO filter self.statuses to remove repeats & out of time people
    
    // work through all new tweets (ie users) - for each:
    // work through all tweets and look to see if their id is equal to users id
        // replace tweet with new one (most up to date best for time pruning later
        // move on to next ... (assumption here that users are in time order - probably would need to sort these first
    BOOL existingUserReplaced;
    
    // try each user
    for(int i = 0; i< [users count]; i++)
    {
        // 
        
        existingUserReplaced = NO;
        NSString* thisUserID = [[[users objectAtIndex:i] objectForKey:@"user"] objectForKey:@"id_str"];
        // work through each member of the existing array  (for that particular user)
        for(int j = 0; j <[self.statuses count]; j++)
        {
            NSString* existingUserId =  [[[self.statuses objectAtIndex:j] objectForKey:@"user"] objectForKey:@"id_str"];
            // look to see whether user is already in the array so it can be replaced or added
            if([existingUserId isEqualToString:thisUserID])
            {
                [self.statuses replaceObjectAtIndex:j withObject:[users objectAtIndex:i]];
                existingUserReplaced = YES;
                break;
            }
        }
        if(!existingUserReplaced)
        {
            [self.statuses addObject:[users objectAtIndex:i]];
        }
    }
    [self.tweetersTableView reloadData];
}



#pragma mark userInteractions

-(IBAction)reactToSlider:(UISlider*)sender
{
    // slider is not continuous - this gets called once the user stops sliding around.
    // lets round it to nearest 1/2 km
    float distance = sender.value * 2;
    int discreteValue = roundl(distance); // Rounds float to an integer
    distance = discreteValue / 2.0;
    [sender setValue:distance]; // Sets your slider to this value
    // display this distance
    self.rangeLabel.text = [NSString stringWithFormat:@"%.2fkm", distance];
    
    
    // clear the table view....
    [self.statuses removeAllObjects];
    [self.tweetersTableView reloadData];
    
    twitterUsersNearby.searchRangeInKm = distance;
    [twitterUsersNearby updateLocation];
}

@end
