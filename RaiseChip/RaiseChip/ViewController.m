//
//  ViewController.m
//  RaiseChip
//
//  mail:ysczzuli@126.com
//  Created by ysc on 16/2/25.
//  Copyright © 2016年 RaiseChip. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic,strong) CBCentralManager *centralManager;
@property (nonatomic,strong) NSMutableArray *peripherals;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (weak, nonatomic) IBOutlet UIButton *lockBtn;
@property (weak, nonatomic) IBOutlet UIButton *unlockBtn;

@end

@implementation ViewController

- (CBCentralManager *)centralManager {

    if (!_centralManager) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return _centralManager;
}
- (NSMutableArray *)peripherals
{
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

static NSString * const kServiceUUID = @"FFE5";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setBtnCornerRadius];
    // 1.中央管理者 lazy
    // 2.扫描设备  --> 发现设备  -->展示设备  -->选择设备 -->连接设备
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    
}
#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"centralManagerDidUpdateState:%ld",(long)central.state);
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            [self scanBluetooth];               //很重要，当蓝牙处于打开状态，开始扫描。
            break;
        default:
            NSLog(@"蓝牙未工作在正确状态");
            break;
    }
}
- (void)scanBluetooth {

    NSDictionary *optionDic = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [_centralManager scanForPeripheralsWithServices:nil options:optionDic];
    NSLog(@"centralManager: %@",_centralManager);
}

/**
 *  发现设备时调用
 *
 *  @param central           中央管理者
 *  @param peripheral        设备
 *  @param advertisementData 广告信息
 *  @param RSSI              信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![self.peripherals containsObject:peripheral]) {
        [self.peripherals addObject:peripheral];
    }

    // 这里添加一个列表供用户选择
    NSLog(@"peripheral : %@",peripheral);

    [self.peripherals enumerateObjectsUsingBlock:^(CBPeripheral  *peripheral, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([peripheral.name isEqualToString:@"Tv221u-796A7148"]) {
            [self connectPeripheral:peripheral];
            *stop = YES;
        }
    }];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral
{
    [self.centralManager connectPeripheral:peripheral options:nil];
    NSLog(@"%s",__func__);
}


/**
 *  当设备已连接时调用
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"%s",__func__);
    // 3.扫描服务
    //扫描所有服务
    [peripheral discoverServices:nil];
    //设置代理
    peripheral.delegate = self;
}

/**
 *  当扫描到服务时调用
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"\n\n peripheral.services%@",peripheral.services);
    // 遍历所有服务
    for (CBService *service in peripheral.services) {
        // 找到需要的服务
        if ([service.UUID.UUIDString isEqualToString:@"FFE5"]) {
            // 4.扫描特征
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

/**
 *  当扫描到特征时调用
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"service.characteristics : %@",service.characteristics);
    // 遍历所有特征
    for (CBCharacteristic *characteristic in service.characteristics) {
        //  找到需要的特征
        if ([characteristic.UUID.UUIDString isEqualToString:@"FFE9"]) {
            NSLog(@"\n== characteristic: %@",characteristic);
            // 发送数据
            // 读取数据
            [peripheral readValueForCharacteristic:characteristic];
            
            int data1 = 0x0014;
            NSData *data = [NSData dataWithBytes:&data1 length:2];
            NSLog(@"data: %@",data);
            
            // 写入数据
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    }
}

- (void)writeData {

    int data1 = 0014;
    
    NSData *data = [NSData dataWithBytes:&data1 length:20];
}


#pragma mark Set UI

- (void)setBtnCornerRadius{

    self.lockBtn.layer.masksToBounds = YES;
    self.lockBtn.layer.cornerRadius = 40;
    
    self.unlockBtn.layer.masksToBounds = YES;
    self.unlockBtn.layer.cornerRadius = 40;
    
}

@end
