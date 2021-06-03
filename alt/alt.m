#import "alt.h" 

NSString *requestUrl = @"https://translate.ilivedata.com/api/v2/translate";
NSString *host = @"translate.ilivedata.com";
NSString *path = @"/api/v2/translate";
NSString *pid = @"51000024"; // your alt project ID
NSString *secretKey = @"xxxxxxx-xxxxxx-xxxxx-xxxxxxx";  // your alt project secret key

@implementation NSString (URLEncoding)
- (nullable NSString *)stringByAddingPercentEncodingForRFC3986 {
    NSString *unreserved = @"-._~";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                    alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    return [self
          stringByAddingPercentEncodingWithAllowedCharacters:
          allowed];
}
@end

@implementation AltDemo 

+ (NSString*)hmacSHA256:(NSString*)data withKey:(NSString*)key {
    const char *cKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *hash = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];

    return [AltDemo base64forData:hash];
}

+ (NSString*)base64forData:(NSData*)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];

    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;

    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {  value |= (0xFF & input[j]);  }  }  NSInteger theIndex = (i / 3) * 4;  output[theIndex + 0] = table[(value >> 18) & 0x3F];
        output[theIndex + 1] = table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6) & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0) & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@end

// clang -framework Foundation alt.m -o alt
int main (int argc, const char * argv[])
{
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc]init];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
    NSString* dateTime = [formatter stringFromDate:[NSDate date]];

    NSDictionary *paramMap = [NSDictionary dictionary];
    paramMap = @{
        @"q": @"Hello World!", 
        @"source": @"en", 
        @"target": @"zh-CN", 
        @"timeStamp": dateTime, 
        @"appId": pid
    };

    NSString *calcSignStr = @"POST\n";
    calcSignStr = [calcSignStr stringByAppendingString: [NSString stringWithFormat:@"%@\n", host]];
    calcSignStr = [calcSignStr stringByAppendingString: [NSString stringWithFormat:@"%@\n", path]];

    NSArray *keys = [paramMap allKeys];
	NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
    	return [a compare:b];
	}];
	
    NSString *httpBody = @"";
    for (NSString *key in sortedKeys) {
        NSString *valueStr = [NSString stringWithFormat:@"%@=%@&", [key stringByAddingPercentEncodingForRFC3986], [[paramMap objectForKey:key] stringByAddingPercentEncodingForRFC3986]];
        calcSignStr = [calcSignStr stringByAppendingString: valueStr];
		httpBody = [httpBody stringByAppendingString: valueStr];
    }
    calcSignStr = [calcSignStr substringToIndex:[calcSignStr length] - 1];
    httpBody = [httpBody substringToIndex:[httpBody length] - 1];
    
	NSString *signature = [AltDemo hmacSHA256:calcSignStr withKey:secretKey];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString: requestUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [request setValue:signature forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody: [httpBody dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
    }];

    [task resume];

    [NSThread sleepForTimeInterval:5.0];  // for wait async task

    return 0;
}
