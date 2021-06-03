#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>

@interface AltDemo : NSObject

+ (NSString*)hmacSHA256:(NSString*)data withKey:(NSString *)key;
+ (NSString*)base64forData:(NSData*)theData;

@end
