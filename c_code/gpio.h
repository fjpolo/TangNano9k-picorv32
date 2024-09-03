#ifndef GPIO_H
#define GPIO_H

#define GPIO0_DATA  ((volatile unsigned int *) 0x80000020)
#define GPIO0_DIR   ((volatile unsigned int *) 0x80000021)

extern void gpio0_set_dir(const unsigned int dir);
extern unsigned int gpio0_get_dir(void);
extern void gpio0_set_data(const unsigned int data);
extern unsigned int gpio0_get_data(void);

#endif // GPIO_H