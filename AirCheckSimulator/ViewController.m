//
//  ViewController.m
//  AirCheckSimulator
//
//  Created by Sam Dickson on 5/30/14.
//  Copyright (c) 2014 Fluke Networks. All rights reserved.
//

#import "ViewController.h"
#define MTU 20
#define SEND_TYPE_STRING 0
#define SEND_TYPE_DATA 1

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITableView *netListView;
@property (weak, nonatomic) IBOutlet UILabel *lblNumNetworks;

@end

@implementation ViewController

NSMutableArray *netlist;
NSMutableData *recvData;
static NSString* const KServiceUUID = @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString* const KCharacteristicReadableUUID = @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString* const KCharacteristicWriteableUUID = @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    netlist = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [netlist count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    NetlistRow *cell = (NetlistRow *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"NetlistRow" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSArray *rowData = [[netlist objectAtIndex:indexPath.row] componentsSeparatedByString: @";"];
    
    //signal here
    int ss = [rowData[1] intValue];
    if(ss > -70)
    {
        cell.imgSignal.image = [UIImage imageNamed:@"signal_5.png"];
    }
    else if(ss > -90 && ss <= -70)
    {
        cell.imgSignal.image = [UIImage imageNamed:@"signal_4.png"];
    }
    else if(ss > -100 && ss <= -90)
    {
        cell.imgSignal.image = [UIImage imageNamed:@"signal_3.png"];
    }
    else if(ss > -119 && ss <= -100)
    {
        cell.imgSignal.image = [UIImage imageNamed:@"signal_2.png"];
    }
    else if(ss > -120 && ss <= -119)
    {
        cell.imgSignal.image = [UIImage imageNamed:@"signal_1.png"];
    }
    else if(ss < -120)
    {
        cell.imgSignal.image = [UIImage imageNamed:@"signal_0.png"];
    }
    
    
    cell.lblSSID.text = rowData[0];
    cell.lbldbm.text = rowData[1];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSArray *ssid = [[netlist objectAtIndex:indexPath.row] componentsSeparatedByString: @";"];
    NSLog(@"Pressed at %@", ssid[0]);
    self.data = [[NSString stringWithFormat:@"%d", indexPath.row] dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheral writeValue:self.data forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (IBAction)btnTransferPressed:(id)sender
{
    [netlist removeAllObjects];
    [_netListView reloadData];
    [self.lblNumNetworks setText:@"Scanning for Networks..."];
    self.data = [@"REFRESH" dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheral writeValue:self.data forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch(central.state)
    {
        case CBCentralManagerStatePoweredOn:
            [self.manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:KServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
            //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Scanning for peripherals..."];
            NSLog(@"Scanning for peripherals...");
            break;
        default:
            //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Bluetooth LE is unsupported!"];
            NSLog(@"Bluetooth LE is unsupported.");
            break;
    }
}

- (void)sendData:(int)data_type
{
    if(self.dataIndex >= self.data.length)
    {
        return;
    }
    
    BOOL doneSending = NO;
    
    while(!doneSending)
    {
        NSInteger sendAmt = self.data.length - self.dataIndex;
        
        if(sendAmt > MTU)
        {
            sendAmt = MTU;
        }
        
        NSData *packet = [NSData dataWithBytes:self.data.bytes+self.dataIndex length:sendAmt];
        NSLog(@"Sending packet: %@", packet.description);
        
        switch(data_type)
        {
            case SEND_TYPE_STRING:
                [self.peripheral writeValue:packet forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
                break;
            case SEND_TYPE_DATA:
                [self.peripheral writeValue:packet forCharacteristic:self.dataCharacteristic type:CBCharacteristicWriteWithoutResponse];
                break;
        }
        
        self.dataIndex += sendAmt;
        
        if(self.dataIndex >= self.data.length)
        {
            switch(data_type)
            {
                case SEND_TYPE_STRING:
                    [self.peripheral writeValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.writebackCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    break;
                case SEND_TYPE_DATA:
                    [self.peripheral writeValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.dataCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    break;
            }
            doneSending = YES;
            return;
        }
        
        packet = nil;
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error writing to characteristic:", [error localizedDescription]];
        NSLog(@"Error writing to characteristic: %@ (code %d)", [error localizedDescription], [error code]);
    }
}

- (void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Found peripheral! Stopping scan."];
    [self.manager stopScan];
    
    if(self.peripheral != peripheral)
    {
        self.peripheral = peripheral;
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Connecting to peripheral: ", peripheral];
        NSLog(@"Connecting to peripheral %@", peripheral);
        [   self.manager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //[self.data setLength:0];
    [self.peripheral setDelegate:self];
    //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Connected!"];
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:KServiceUUID]]];
    //[self.disconnect setEnabled:YES];
    //self.status.text = [NSString stringWithFormat:@"Connected to %@", [peripheral.identifier UUIDString]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error discovering service: ", [error localizedDescription]];
        NSLog(@"Error discovering service: %@", [error localizedDescription]);
        //[self cleanup];
        return;
    }
    
    for(CBService *service in peripheral.services)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Found service with UUID: ", service.UUID];
        NSLog(@"Found service with UUID: %@", service.UUID);
        if([service.UUID isEqual:[CBUUID UUIDWithString:KServiceUUID]])
        {
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:KCharacteristicReadableUUID]] forService:service];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:KCharacteristicWriteableUUID]] forService:service];
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error discovering characteristic: ", [error localizedDescription]];
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        return;
    }
    
    if([service.UUID isEqual:[CBUUID UUIDWithString:KServiceUUID]])
    {
        for(CBCharacteristic *characteristic in service.characteristics)
        {
            //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Discovered characteristic with UUID: ", characteristic.UUID];
            //NSLog(@"Discovered characteristic with UUID: %@", characteristic.UUID);
            
            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicReadableUUID]])
            {
                //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Discovered READABLE characteristic."];
                NSLog(@"Discovered READABLE characteristic");
                self.peripheralCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.peripheralCharacteristic];
            }
            else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicWriteableUUID]])
            {
                //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Discovered WRITEABLE characteristic."];
                NSLog(@"Discovered WRITEABLE characteristic");
                self.writebackCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:self.writebackCharacteristic];
            }
            
        }
    }
}

- (void)peripheral:(CBPeripheral*)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Error changing notification state: ", [error localizedDescription]];
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
        return;
    }
    
    if(!([characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicReadableUUID]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:KCharacteristicWriteableUUID]]))
    {
        return;
    }
    
    if(characteristic.isNotifying)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Notification began on ", characteristic];
        NSLog(@"Notification began on %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    }
    else
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@ %@", self.console.text, @"Notification stopped on ", characteristic];
        NSLog(@"Notification has stopped on %@", characteristic);
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        //self.console.text = [NSString stringWithFormat:@"%@\n%@", self.console.text, @"Error reading updated characteristic value: ", [error localizedDescription]];
        NSLog(@"Error reading updated characteristic value: %@", [error localizedDescription]);
        return;
    }
    
    
    NSString *str = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    //NSLog(@"Added count is %d", [self.graphView.data count]);
    
    //NSLog(@"Data in: %@", str);
    
    
    if([str isEqualToString:@"EOM"])
    {
        if(recvData != nil)
        {
            //NSLog(@"DONE RECV");
            NSData *final = [[NSData alloc] initWithData:recvData];
            //NSLog(@"I got: %@", [[NSString alloc] initWithData:final encoding:NSUTF8StringEncoding]);

            
            [netlist addObject:[[NSString alloc] initWithData:final encoding:NSUTF8StringEncoding]];
            [_netListView reloadData];
            [self.lblNumNetworks setText:[NSString stringWithFormat:@"Found %d Networks.", [netlist count]]];
            recvData = nil;
        }
     }
     else
     {
         if(recvData == nil)
         {
             recvData = [[NSMutableData alloc] initWithData:characteristic.value];
         }
         else
         {
             [recvData appendData:characteristic.value];
         }
     }
}


@end
