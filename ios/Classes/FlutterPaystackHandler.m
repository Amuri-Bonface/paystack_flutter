#import "FlutterPaystackHandler.h"
#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h> // Note: You'll need to add AFNetworking or Alamofire to your iOS project

@interface FlutterPaystackHandler ()

@property (nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;
@property (nonatomic, strong) AFHTTPSessionManager *httpManager;
@property (nonatomic, strong) NSString *publicKey;
@property (nonatomic, strong) NSString *environment;

@end

@implementation FlutterPaystackHandler

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    
    if (self) {
        _registrar = registrar;
        [self setupHttpManager];
    }
    
    return self;
}

- (void)setupHttpManager {
    _httpManager = [AFHTTPSessionManager manager];
    _httpManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Set base URL based on environment
    NSString *baseURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"PaystackBaseURL"];
    if (!baseURL) {
        baseURL = @"https://api.paystack.co";
    }
    
    _httpManager.requestSerializer.timeoutInterval = 30;
    _httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
}

- (void)processPayment:(NSDictionary *)paymentRequest
              onSuccess:(void (^)(NSDictionary *response))onSuccess
                onError:(void (^)(NSString *errorMessage, NSDictionary *errorDetails))onError {
    
    NSString *email = paymentRequest[@"email"];
    NSNumber *amount = paymentRequest[@"amount"];
    NSString *currency = paymentRequest[@"currency"] ?: @"KES";
    NSString *reference = paymentRequest[@"reference"];
    NSString *paymentMethod = paymentRequest[@"paymentMethod"];
    
    // Validate required fields
    if (!email || [email length] == 0) {
        onError(@"Email is required", @{@"code": @"INVALID_EMAIL"});
        return;
    }
    
    if (!amount || [amount integerValue] <= 0) {
        onError(@"Amount must be greater than 0", @{@"code": @"INVALID_AMOUNT"});
        return;
    }
    
    NSString *serverUrl = [self.serverUrl stringByAppendingString:@"/transaction/initialize"];
    
    // Create transaction data
    NSMutableDictionary *transactionData = [[NSMutableDictionary alloc] init];
    transactionData[@"email"] = email;
    transactionData[@"amount"] = amount;
    transactionData[@"currency"] = currency;
    transactionData[@"reference"] = reference;
    transactionData[@"callback_url"] = @"flutter_paystack://callback";
    
    // Add channel-specific parameters
    if ([paymentMethod isEqualToString:@"mobile_money"]) {
        NSString *phone = paymentRequest[@"phone"];
        if (phone) {
            transactionData[@"mobileMoney"] = @{@"phone": phone};
        }
    } else if ([paymentMethod isEqualToString:@"bank_transfer"]) {
        transactionData[@"bank"] = @{@"code": paymentRequest[@"bankCode"]};
    }
    
    // Set authorization header
    [_httpManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", self.publicKey]
                          forHTTPHeaderField:@"Authorization"];
    
    [_httpManager POST:serverUrl
            parameters:transactionData
              progress:nil
               success:^(NSURLSessionDataTask *task, id responseObject) {
                   NSDictionary *response = responseObject;
                   
                   if ([response[@"status"] boolValue]) {
                       onSuccess(@{@"reference": response[@"data"][@"reference"],
                                  @"authorization_url": response[@"data"][@"authorization_url"],
                                  @"access_code": response[@"data"][@"access_code"]});
                   } else {
                       onError(response[@"message"] ?: @"Payment initialization failed", 
                              @{@"code": @"INITIALIZATION_FAILED"});
                   }
               }
               failure:^(NSURLSessionDataTask *task, NSError *error) {
                   NSString *errorMessage = [self getErrorMessage:error];
                   onError(errorMessage, @{@"code": @"NETWORK_ERROR", @"underlying_error": error.localizedDescription});
               }];
}

- (void)verifyTransaction:(NSString *)reference
                 onSuccess:(void (^)(NSDictionary *response))onSuccess
                   onError:(void (^)(NSString *errorMessage, NSDictionary *errorDetails))onError {
    
    if (!reference || [reference length] == 0) {
        onError(@"Reference is required", @{@"code": @"INVALID_REFERENCE"});
        return;
    }
    
    NSString *serverUrl = [NSString stringWithFormat:@"%@/transaction/verify/%@", self.serverUrl, reference];
    
    // Set authorization header
    [_httpManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", self.publicKey]
                          forHTTPHeaderField:@"Authorization"];
    
    [_httpManager GET:serverUrl
            parameters:nil
              progress:nil
               success:^(NSURLSessionDataTask *task, id responseObject) {
                   NSDictionary *response = responseObject;
                   
                   if ([response[@"status"] boolValue]) {
                       NSDictionary *data = response[@"data"];
                       BOOL success = [data[@"status"] isEqualToString:@"success"];
                       
                       onSuccess(@{@"verified": @(success),
                                  @"amount": data[@"amount"],
                                  @"currency": data[@"currency"],
                                  @"reference": data[@"reference"],
                                  @"status": data[@"status"]});
                   } else {
                       onError(response[@"message"] ?: @"Verification failed", 
                              @{@"code": @"VERIFICATION_FAILED"});
                   }
               }
               failure:^(NSURLSessionDataTask *task, NSError *error) {
                   NSString *errorMessage = [self getErrorMessage:error];
                   onError(errorMessage, @{@"code": @"NETWORK_ERROR", @"underlying_error": error.localizedDescription});
               }];
}

#pragma mark - Helper Methods

- (NSString *)getErrorMessage:(NSError *)error {
    if (error.code == NSURLErrorNotConnectedToInternet) {
        return @"No internet connection";
    } else if (error.code == NSURLErrorTimedOut) {
        return @"Request timed out";
    } else if (error.code == NSURLErrorCannotFindHost) {
        return @"Cannot connect to server";
    } else {
        return error.localizedDescription ?: @"An unexpected error occurred";
    }
}

- (NSString *)serverUrl {
    if ([self.environment isEqualToString:@"live"] || [self.environment isEqualToString:@"production"]) {
        return @"https://api.paystack.co";
    } else {
        return @"https://sandbox-api.paystack.co";
    }
}

@end