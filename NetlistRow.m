//
//  NetlistRow.m
//  AirCheckSimulator
//
//  Created by Sam Dickson on 5/30/14.
//  Copyright (c) 2014 Fluke Networks. All rights reserved.
//

#import "NetlistRow.h"

@implementation NetlistRow

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
