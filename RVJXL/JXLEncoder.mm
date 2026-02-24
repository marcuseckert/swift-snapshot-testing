//
//  JXLEncoder.m
//  SnapshotTesting
//
//  Created by Marcus Eckert on 16.10.25.
//

#import <Foundation/Foundation.h>


#import "JXLEncoder.h"
#include <jxl/encode_cxx.h>
#include <jxl/decode.h>
#include <jxl/thread_parallel_runner.h>
#include <vector>
#import "JXLContext.h"
#include <memory>

@implementation JXLEncoder

+ (nullable NSData *)encodeCGImage:(CGImageRef)image
                           quality:(float)quality
                            effort:(NSInteger)effort {
  if (!image) return nil;

  size_t width = CGImageGetWidth(image);
  size_t height = CGImageGetHeight(image);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  std::vector<uint8_t> pixelData(height * width * 4);

  CGContextRef context = CGBitmapContextCreate(
                                               pixelData.data(),
                                               width,
                                               height,
                                               8,
                                               width * 4,
                                               colorSpace,
                                               (uint)kCGImageAlphaPremultipliedLast | (uint)kCGBitmapByteOrder32Big
                                               );

  CGColorSpaceRelease(colorSpace);

  if (!context) return nil;

  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
  CGContextRelease(context);

  auto enc = JxlEncoderMake(nullptr);
  if (!enc) return nil;

  auto runner = [JXLContext getRunner];

  if (JXL_ENC_SUCCESS != JxlEncoderSetParallelRunner(enc.get(),
                                                     JxlThreadParallelRunner,
                                                     runner)) {
    return nil;
  }

  JxlBasicInfo basic_info;
  JxlEncoderInitBasicInfo(&basic_info);
  basic_info.xsize = (uint32_t)width;
  basic_info.ysize = (uint32_t)height;
  basic_info.bits_per_sample = 8;
  basic_info.exponent_bits_per_sample = 0;
  basic_info.uses_original_profile = JXL_TRUE;
  basic_info.num_color_channels = 3;
  basic_info.num_extra_channels = 1; // Alpha channel
  basic_info.alpha_bits = 8;
  basic_info.alpha_exponent_bits = 0;

  if (JXL_ENC_SUCCESS != JxlEncoderSetBasicInfo(enc.get(), &basic_info)) {
    return nil;
  }


  auto* frame_settings = JxlEncoderFrameSettingsCreate(enc.get(), nullptr);

  float distance = 1.0f - quality;
  distance = distance * 25.0f;
  if (distance < 0.0f) distance = 0.0f;

  JxlEncoderSetFrameDistance(frame_settings, distance);
  JxlEncoderSetFrameLossless(frame_settings, distance < 0.01f ? JXL_TRUE : JXL_FALSE);

  JxlEncoderFrameSettingsSetOption(frame_settings,
                                   JXL_ENC_FRAME_SETTING_EFFORT,
                                   effort);

  JxlPixelFormat pixel_format = {4, JXL_TYPE_UINT8, JXL_NATIVE_ENDIAN, 0};

  if (JXL_ENC_SUCCESS != JxlEncoderAddImageFrame(frame_settings,
                                                 &pixel_format,
                                                 pixelData.data(),
                                                 pixelData.size())) {
    return nil;
  }

  JxlEncoderCloseInput(enc.get());

  std::vector<uint8_t> compressed;
  compressed.resize(64);
  uint8_t* next_out = compressed.data();
  size_t avail_out = compressed.size();

  JxlEncoderStatus process_result = JXL_ENC_NEED_MORE_OUTPUT;
  while (process_result == JXL_ENC_NEED_MORE_OUTPUT) {
    process_result = JxlEncoderProcessOutput(enc.get(), &next_out, &avail_out);

    if (process_result == JXL_ENC_NEED_MORE_OUTPUT) {
      size_t offset = next_out - compressed.data();
      compressed.resize(compressed.size() * 2);
      next_out = compressed.data() + offset;
      avail_out = compressed.size() - offset;
    }
  }

  if (process_result != JXL_ENC_SUCCESS) {
    return nil;
  }

  compressed.resize(next_out - compressed.data());

  return [NSData dataWithBytes:compressed.data() length:compressed.size()];
}

@end

