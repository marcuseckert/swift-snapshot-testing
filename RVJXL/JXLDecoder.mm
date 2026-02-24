//
//  JXLDecoder.m
//  RVJXL
//
//  Created by Marcus Eckert on 16.10.25.
//

#import "JXLDecoder.h"
#include <jxl/encode_cxx.h>
#include <jxl/decode.h>
#include <jxl/decode_cxx.h>
#include <jxl/thread_parallel_runner.h>
#include <vector>
#include "JXLContext.h"

@implementation JXLDecoder

static std::vector<uint8_t> pixels;

+ (nullable CGImageRef)decodeData:(NSData *)data CF_RETURNS_RETAINED {
  if (!data || data.length == 0) return nil;

  auto dec = JxlDecoderMake(nullptr);
  if (!dec) return nil;

  auto runner =  [JXLContext getRunner];

  if (JXL_DEC_SUCCESS != JxlDecoderSetParallelRunner(dec.get(),
                                                     JxlThreadParallelRunner,
                                                     runner)) {
    return nil;
  }

  if (JXL_DEC_SUCCESS != JxlDecoderSubscribeEvents(
                                                   dec.get(), JXL_DEC_BASIC_INFO | JXL_DEC_FULL_IMAGE)) {
                                                     return nil;
                                                   }

  const uint8_t* jxl_data = (const uint8_t*)data.bytes;
  size_t jxl_size = data.length;
  JxlDecoderSetInput(dec.get(), jxl_data, jxl_size);
  JxlDecoderCloseInput(dec.get());

  JxlBasicInfo info;
  std::vector<uint8_t> pixels;
  size_t size = 0;

  for (;;) {
    JxlDecoderStatus status = JxlDecoderProcessInput(dec.get());

    if (status == JXL_DEC_ERROR) {
      return nil;
    } else if (status == JXL_DEC_NEED_MORE_INPUT) {
      return nil;
    } else if (status == JXL_DEC_BASIC_INFO) {
      if (JXL_DEC_SUCCESS != JxlDecoderGetBasicInfo(dec.get(), &info)) {
        return nil;
      }

      size_t num_pixels = info.xsize * info.ysize;
      size = num_pixels*4;
      if (pixels.size() < (num_pixels * 4)) {
        pixels.resize(num_pixels * 4); // RGBA
      }


    } else if (status == JXL_DEC_NEED_IMAGE_OUT_BUFFER) {
      JxlPixelFormat format = {4, JXL_TYPE_UINT8, JXL_NATIVE_ENDIAN, 0};

      if (JXL_DEC_SUCCESS != JxlDecoderSetImageOutBuffer(dec.get(),
                                                         &format,
                                                         pixels.data(),
                                                         size)) {
        return nil;
      }
    } else if (status == JXL_DEC_FULL_IMAGE) {
      break;
    } else if (status == JXL_DEC_SUCCESS) {
      break;
    }
  }

  if (size == 0) return nil;

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(
                                               pixels.data(),
                                               info.xsize,
                                               info.ysize,
                                               8,
                                               info.xsize * 4,
                                               colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big
                                               );

  CGColorSpaceRelease(colorSpace);

  if (!context) return nil;

  CGImageRef image = CGBitmapContextCreateImage(context);
  CGContextRelease(context);

  return image;
}

@end
