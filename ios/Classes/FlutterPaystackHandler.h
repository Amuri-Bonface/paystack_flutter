#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface FlutterPaystackHandler : NSObject

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar;
- (void)processPayment:(NSDictionary *)paymentRequest
              onSuccess:(void (^)(NSDictionary *response))onSuccess
                onError:(void (^)(NSString *errorMessage, NSDictionary *errorDetails))onError;
- (void)verifyTransaction:(NSString *)reference
                 onSuccess:(void (^)(NSDictionary *response))onSuccess
                   onError:(void (^)(NSString *errorMessage, NSDictionary *errorDetails))onError;

@end