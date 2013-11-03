//
//  ViewController.h
//  AppNetClient
//
//  Created by Rueben Anderson on 11/1/13.
//  Copyright (c) 2013 Rueben Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CustomCell.h"

@interface ViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate>
{
    IBOutlet UITableView *postTable;
    NSMutableData *timelineData;
    NSDictionary *timelineJSON;
    NSURLConnection *connectionManager;
    NSMutableDictionary *userImages;
    NSMutableDictionary *imageUrls;
    NSMutableArray *timelineDetails;
    int currentImage;
    int connectionType;
    NSMutableData *avatarData;
    NSString *currentPoster;
    BOOL doRefresh;
    int textHeight;
    
}

- (void)makeRequest:(NSString *) urlString;
- (void)extractJSONCellData;

@end
