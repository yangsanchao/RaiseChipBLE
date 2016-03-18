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
#import "AppDelegate.h"

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic,strong) CBCentralManager *centralManager;  //中央管理者

@property (nonatomic,strong) NSMutableArray *peripherals;       //设备数组
@property (nonatomic, strong) CBPeripheral *peripheral;         //设备
@property (nonatomic, strong) CBCharacteristic *characteristic; //特征


@property (weak, nonatomic) IBOutlet UIButton *lockBtn;
@property (weak, nonatomic) IBOutlet UIButton *unlockBtn;

@property (weak, nonatomic) IBOutlet UIImageView *line;
@property (weak, nonatomic) IBOutlet UIImageView *Hline;
@end

@implementation ViewController

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
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    app.line = self.line;
    app.lockBtn = self.lockBtn;
    app.unlockBtn = self.unlockBtn;
    
    self.line.layer.anchorPoint = CGPointMake(0.15, 0.5);
    
    [self setBtnCornerRadius];
    
    // 1.中央管理者 lazy
    // 2.扫描设备  --> 发现设备  -->展示设备  -->选择设备 -->连接设备
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    
}

- (void)setBtnCornerRadius{
    
    self.lockBtn.layer.masksToBounds = YES;
    self.lockBtn.layer.cornerRadius = 40;
    self.lockBtn.enabled = NO;
    
    self.unlockBtn.layer.masksToBounds = YES;
    self.unlockBtn.layer.cornerRadius = 40;
    self.unlockBtn.enabled = NO;
    
    self.line.layer.masksToBounds = YES;
    self.line.layer.cornerRadius = 5;
    
    self.Hline.layer.masksToBounds = YES;
    self.Hline.layer.cornerRadius = 5;
    
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
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
            [self scanBluetooth];
            //当蓝牙处于打开状态，开始扫描。
            break;
        default:
            NSLog(@"蓝牙未工作在正确状态");
            break;
    }
}
/**
 * 扫描蓝牙设备
 */
- (void)scanBluetooth {
    NSDictionary *optionDic = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [_centralManager scanForPeripheralsWithServices:nil options:optionDic];
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
    //NSLog(@"\n发现的蓝牙设备：peripheral : %@ \n\n",peripheral);

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
    //NSLog(@"\n设备正在连接：%@ \n\n",peripheral);
}


/**
 *  当设备已连接时调用
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //NSLog(@"\n设备已经连接，开始扫描服务：%s\n\n",__func__);
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
    //NSLog(@"\n 已经扫描到设备的服务peripheral.services %@ \n\n",peripheral.services);
    // 遍历所有服务
    for (CBService *service in peripheral.services) {
        // 找到需要的服务
        if ([service.UUID.UUIDString isEqualToString:@"FFE5"]) {
            // 4.扫描特征
            [peripheral discoverCharacteristics:nil forService:service];
            self.peripheral = peripheral;
        }
    }
}

/**
 *  当扫描到特征时调用
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //NSLog(@"\n当扫描到特征时调用：service.characteristics : %@\n\n",service.characteristics);
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        if ([characteristic.UUID.UUIDString isEqualToString:@"FFE9"]) {
            if (error) {
                NSLog(@"didDiscoverCharacteristicsForService error:%@",[error localizedDescription]);
                return;
            }
            self.characteristic = characteristic;
            //将满足条件的特征保存为全局特征，以便对齐进行写入操作。
            self.lockBtn.enabled = YES;
            self.unlockBtn.enabled = YES;
            //NSLog(@"\n满足条件的特征 peripheral: %@ \n\n",self.characteristic);
        }
    }
}

#pragma mark Set UI

- (IBAction)open:(UIButton *)sender {
    [self writeDataWihtCommand:@"dw"];
    self.lockBtn.enabled = NO;

    [UIView animateWithDuration:3 animations:^{
        self.line.transform =  CGAffineTransformMakeRotation(0);
         NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setValue:@(0) forKey:@"value"];
    }completion:^(BOOL finished) {
        self.unlockBtn.enabled = YES;
    }];
    


}


- (IBAction)close:(UIButton *)sender {
    
    [self writeDataWihtCommand:@"up"];
    self.unlockBtn.enabled = NO;

    [UIView animateWithDuration:4 animations:^{
        self.line.transform =  CGAffineTransformMakeRotation(-M_PI_2);
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setValue:@(1) forKey:@"value"];

    }completion:^(BOOL finished) {
        self.lockBtn.enabled = YES;
    }];
    


}

- (void)writeDataWihtCommand:(NSString *)command {
    //write
    NSData *data = [command dataUsingEncoding:NSASCIIStringEncoding];
    [_peripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
}

@end
