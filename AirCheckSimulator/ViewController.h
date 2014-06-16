//
//  ViewController.h
//  AirCheckSimulator
//
//  Created by Sam Dickson on 5/30/14.
//  Copyright (c) 2014 Fluke Networks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "NetlistRow.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate>
@property (strong, nonatomic) CBCentralManager *manager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *peripheralCharacteristic;
@property (strong, nonatomic) CBCharacteristic *writebackCharacteristic;
@property (strong, nonatomic) CBCharacteristic *dataCharacteristic;
@property (nonatomic, readwrite) NSInteger dataIndex;
@property (strong, nonatomic) NSData *data;
@end
