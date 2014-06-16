//
//  NetlistRow.h
//  AirCheckSimulator
//
//  Created by Sam Dickson on 5/30/14.
//  Copyright (c) 2014 Fluke Networks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NetlistRow : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgSignal;
@property (weak, nonatomic) IBOutlet UILabel *lblSSID;
@property (weak, nonatomic) IBOutlet UILabel *lbldbm;
@end
