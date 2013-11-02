//
//  ViewController.h
//  AppNetClient
//
//  Created by Rueben Anderson on 11/1/13.
//  Copyright (c) 2013 Rueben Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomCell.h"

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UITableView *postTable;
    
}

@end
