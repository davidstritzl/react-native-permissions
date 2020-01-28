#import "RNPermissionHandlerBluetoothCentral.h"

@import CoreBluetooth;

@interface RNPermissionHandlerBluetoothCentral() <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager* centralManager;
@property (nonatomic, strong) void (^resolve)(RNPermissionStatus status);
@property (nonatomic, strong) void (^reject)(NSError *error);

@end

@implementation RNPermissionHandlerBluetoothCentral

+ (NSArray<NSString *> * _Nonnull)usageDescriptionKeys {
  return @[
    @"NSBluetoothAlwaysUsageDescription",
  ];
}

+ (NSString * _Nonnull)handlerUniqueId {
  return @"ios.permission.BLUETOOTH_CENTRAL";
}

- (void)checkWithResolver:(void (^ _Nonnull)(RNPermissionStatus))resolve
                 rejecter:(void (__unused ^ _Nonnull)(NSError * _Nonnull))reject {
#if TARGET_OS_SIMULATOR
  return resolve(RNPermissionStatusNotAvailable);
#else

  if (@available(iOS 13.0, *)) {
    switch ([[CBManager new] authorization]) {
      case CBManagerAuthorizationNotDetermined:
        return resolve(RNPermissionStatusNotDetermined);
      case CBManagerAuthorizationRestricted:
        return resolve(RNPermissionStatusRestricted);
      case CBManagerAuthorizationDenied:
        return resolve(RNPermissionStatusDenied);
      case CBManagerAuthorizationAllowedAlways:
        return resolve(RNPermissionStatusAuthorized);
    }
  } else {
    return resolve(RNPermissionStatusAuthorized);
  }
#endif
}

- (void)requestWithResolver:(void (^ _Nonnull)(RNPermissionStatus))resolve
                   rejecter:(void (^ _Nonnull)(NSError * _Nonnull))reject {
  _resolve = resolve;
  _reject = reject;

  _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{
    CBCentralManagerOptionShowPowerAlertKey: @false,
  }];
}

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
  switch (central.state) {
    case CBManagerStatePoweredOff:
    case CBManagerStateResetting:
    case CBManagerStateUnsupported:
      return _resolve(RNPermissionStatusNotAvailable);
    case CBManagerStateUnknown:
      return _resolve(RNPermissionStatusNotDetermined);
    case CBManagerStateUnauthorized:
      return _resolve(RNPermissionStatusDenied);
    case CBManagerStatePoweredOn:
      return [self checkWithResolver:_resolve rejecter:_reject];
  }
}

@end
