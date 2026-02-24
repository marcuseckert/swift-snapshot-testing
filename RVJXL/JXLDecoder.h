//
//  JXLDecoder.h
//  RVJXL
//
//  Created by Marcus Eckert on 16.10.25.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface JXLDecoder : NSObject

+ (nullable CGImageRef)decodeData:(NSData *)data CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END
