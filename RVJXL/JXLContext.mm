//
//  JXLContext.m
//  RVJXL
//
//  Created by Marcus Eckert on 16.10.25.
//

#import "JXLContext.h"
#include <memory.h>
#include <jxl/encode_cxx.h>
#include <jxl/decode.h>
#include <jxl/decode_cxx.h>
#include <jxl/thread_parallel_runner.h>
#include <jxl/thread_parallel_runner.h>

static void* _runner = nil;
@interface JXLContext() {
}
@end

@implementation JXLContext

+(void*)getRunner {
//  if (!_runner) {
    _runner = JxlThreadParallelRunnerCreate(nullptr,
                                                JxlThreadParallelRunnerDefaultNumWorkerThreads()
                                                );
  return _runner;
}

@end
