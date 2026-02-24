//
//  RVJXLEncoder.h
//  SnapshotTesting
//
//  Created by Marcus Eckert on 16.10.25.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface JXLEncoder : NSObject

+ (nullable NSData *)encodeCGImage:(CGImageRef)image
                           quality:(float)quality
                            effort:(NSInteger)effort;

@end

