#include "gpio.h"

void gpio0_set_dir(const unsigned int dir){
    *GPIO0_DIR = dir;
}
unsigned int gpio0_get_dir(void){
    return (unsigned int)*GPIO0_DIR;
}
void gpio0_set_data(const unsigned int data){
    *GPIO0_DATA = data;
}
unsigned int gpio0_get_data(void){
    return (unsigned int)*GPIO0_DATA;
}