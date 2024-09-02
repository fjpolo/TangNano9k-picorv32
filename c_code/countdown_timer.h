#ifndef COUNTDOWN_TIMER_H
#define COUNTDOWN_TIMER_H

/* Copyright 2024 Grug Huhler
 *
 * License: SPDX BSD-2-Clause.
 */

#define CDT_COUNTER ((volatile unsigned int *) 0x80000010)
#define CDT_COUNTER_H0 ((volatile unsigned short *) 0x80000010)
#define CDT_COUNTER_H2 ((volatile unsigned short *) 0x80000012)
#define CDT_COUNTER_B0 ((volatile unsigned char *) 0x80000010)
#define CDT_COUNTER_B1 ((volatile unsigned char *) 0x80000011)
#define CDT_COUNTER_B2 ((volatile unsigned char *) 0x80000012)
#define CDT_COUNTER_B3 ((volatile unsigned char *) 0x80000013)

extern void cdt_wbyte0(const unsigned char value);
extern void cdt_wbyte1(const unsigned char value);
extern void cdt_wbyte2(const unsigned char value);
extern void cdt_wbyte3(const unsigned char value);

extern void cdt_whalf0(const unsigned short value);
extern void cdt_whalf2(const unsigned short value);

extern void cdt_write(const unsigned int value);
extern unsigned int cdt_read(void);
extern void cdt_delay(const unsigned int value);
#endif

