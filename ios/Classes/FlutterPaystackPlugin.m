#import "FlutterPaystackPlugin.h"
#import "FlutterPaystackHandler.h"
#import <UIKit/UIKit.h>

@implementation FlutterPaystackPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"flutter_paystack"
                                                          binaryMessenger:[registrar messenger]];
    
    FlutterPaystackPlugin *instance = [[FlutterPaystackPlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    
    if (self) {
        _registrar = registrar;
        _handler = [[FlutterPaystackHandler alloc] initWithRegistrar:registrar];
    }
    
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    @try {
        if ([call.method isEqualToString:@"initialize"]) {
            [self initialize:call result:result];
        } else if ([call.method isEqualToString:@"processPayment"]) {
            [self processPayment:call result:result];
        } else if ([call.method isEqualToString:@"verifyTransaction"]) {
            [self verifyTransaction:call result:result];
        } else if ([call.method isEqualToString:@"getAccessCode"]) {
            [self getAccessCode:call result:result];
        } else {
            result(FlutterMethodNotImplemented);
        }
    } @catch (NSException *exception) {
        NSLog(@"FlutterPaystackPlugin Error: %@", exception.reason);
        result([FlutterError errorWithCode:@"PLUGIN_ERROR"
                                   message:[NSString stringWithFormat:@"Error processing method call: %@", exception.reason]
                                   details:nil]);
    }
}

- (void)initialize:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *publicKey = call.arguments[@"publicKey"];
    NSString *environment = call.arguments[@"environment"];
    
    if (!publicKey || [publicKey length] == 0) {
        result([FlutterError errorWithCode:@"INVALID_PUBLIC_KEY"
                                   message:@"Public key cannot be null or empty"
                                   details:nil]);
        return;
    }
    
    NSLog(@"Initializing Paystack with public key: %@", publicKey);
    
    // Initialize Paystack SDK
    // Note: You need to add the Paystack framework to your iOS project
    // This is a placeholder implementation - actual initialization depends on Paystack iOS SDK
    
    result(@{@"status": @"success", @"message": @"Paystack initialized successfully"});
}

- (void)processPayment:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = call.arguments;
    
    if (!arguments[@"email"] || [arguments[@"email"] length] == 0) {
        result([FlutterError errorWithCode:@"INVALID_EMAIL"
                                   message:@"Email cannot be null or empty"
                                   details:nil]);
        return;
    }
    
    if ([arguments[@"amount"] integerValue] <= 0) {
        result([FlutterError errorWithCode:@"INVALID_AMOUNT"
                                   message:@"Amount must be greater than 0"
                                   details:nil]);
        return;
    }
    
    NSString *email = arguments[@"email"];
    NSNumber *amount = arguments[@"amount"];
    NSString *currency = arguments[@"currency"] ?: @"NGN";
    NSString *reference = arguments[@"reference"];
    NSString *paymentMethod = arguments[@"paymentMethod"];
    
    NSLog(@"Processing payment: %@ %@ for %@", amount, currency, email);
    
    // Create payment request
    NSDictionary *paymentRequest = @{
        @"email": email,
        @"amount": amount,
        @"currency": currency,
        @"reference": reference ?: [NSString stringWithFormat:@"ref_%@", @([[NSDate date] timeIntervalSince1970])],
        @"paymentMethod": paymentMethod
    };
    
    // Delegate to handler
    [self.handler processPayment:paymentRequest
                        onSuccess:^(NSDictionary *response) {
                            result(@{@"status": @"success", @"data": response});
                        }
                        onError:^(NSString *errorMessage, NSDictionary *errorDetails) {
                            result([FlutterError errorWithCode:@"PAYMENT_FAILED"
                                                       message:errorMessage
                                                       details:errorDetails]);
                        }];
}

- (void)verifyTransaction:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *reference = call.arguments[@"reference"];
    
    if (!reference || [reference length] == 0) {
        result([FlutterError errorWithCode:@"INVALID_REFERENCE"
                                   message:@"Reference cannot be null or empty"
                                   details:nil]);
        return;
    }
    
    NSLog(@"Verifying transaction: %@", reference);
    
    // Delegate to handler
    [self.handler verifyTransaction:reference
                           onSuccess:^(NSDictionary *response) {
                               result(@{@"status": @"success", @"data": response});
                           }
                           onError:^(NSString *errorMessage, NSDictionary *errorDetails) {
                               result([FlutterError errorWithCode:@"VERIFICATION_FAILED"
                                                          message:errorMessage
                                                          details:errorDetails]);
                           }];
}

- (void)getAccessCode:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *accessCode = [NSString stringWithFormat:@"pk_%@", @([[NSDate date] timeIntervalSince1970])];
    result(accessCode);
}

@end