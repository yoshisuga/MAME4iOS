//
//  Timers.h
//  Wombat
//
//  Created by Todd Laney on 4/6/20.
//  Copyright © 2020 Todd Laney. All rights reserved.
//

//
// light weight code timers.  these timers only generate code in the DEBUG build (or if WANT_TIMERS is defined)
//
// USAGE:
//
// declare timers at top of file:
//
//      TIMER_INIT_BEGIN
//      TIMER_INIT(timer_name_1)
//      TIMER_INIT(timer_name_2)
//      TIMER_INIT_END
//
// surround code you want to time with TIMER_BEGIN and TIMER_END
//
//      TIMER_BEGIN(timer_name_1)
//      ...some code...
//      TIMER_END(timer_name_1)
//
// print out timer status via NSLog
//
//      TIMER_DUMP()
//
// reset all timers back to zero
//
//      TIMER_RESET()
//
#if defined(DEBUG) || defined(WANT_TIMERS)
typedef struct _TIMER {
    char *          name;
    NSTimeInterval  time;
    NSUInteger      count;
} TIMER;
#define TIMER_INIT_BEGIN enum {
#define TIMER_INIT(name) TIMER_##name,
#define TIMER_INIT_END TIMER_COUNT}; static TIMER __timers[TIMER_COUNT];
#define TIMER_START(t) \
    __timers[TIMER_##t].name = #t; \
    __timers[TIMER_##t].time -= CACurrentMediaTime();
#define TIMER_STOP(t) \
    __timers[TIMER_##t].time += CACurrentMediaTime(); \
    __timers[TIMER_##t].count++;
#define TIMER_COUNT(t) __timers[TIMER_##t].count
#define TIMER_TIME(t)  __timers[TIMER_##t].time
#define TIMER_DUMP() \
    for (int i=0; i<TIMER_COUNT; i++) { \
        if (__timers[i].name) \
            NSLog(@" %-20s: %4ld %0.3lfs total, %0.3lfms average", __timers[i].name, __timers[i].count, __timers[i].time, __timers[i].count != 0 ? (__timers[i].time * 1000.0 / __timers[i].count) : 0); \
    }
#define TIMER_RESET() \
    for (int i=0; i<TIMER_COUNT; i++) {__timers[i].time = __timers[i].count = 0;}
#else
#define TIMER_INIT_BEGIN
#define TIMER_INIT(name)
#define TIMER_INIT_END
#define TIMER_START(t)
#define TIMER_STOP(t)
#define TIMER_COUNT(t) 0
#define TIMER_TIME(t) 0
#define TIMER_DUMP()
#define TIMER_RESET()
#endif

