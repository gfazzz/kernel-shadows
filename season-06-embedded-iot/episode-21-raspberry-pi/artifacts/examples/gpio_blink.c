/*
 * GPIO LED Blink Example - Raspberry Pi
 * Episode 21: KERNEL SHADOWS
 * 
 * Compile: gcc gpio_blink.c -o blink -lgpiod
 * Run: sudo ./blink
 */

#include <gpiod.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#define GPIO_CHIP "gpiochip0"
#define LED_PIN 17  // GPIO 17 (Physical pin 11)

int main() {
    struct gpiod_chip *chip;
    struct gpiod_line *line;
    int ret;
    
    printf("GPIO LED Blink - Episode 21\n");
    printf("Using GPIO%d (pin 11)\n\n", LED_PIN);
    
    // Open GPIO chip
    chip = gpiod_chip_open_by_name(GPIO_CHIP);
    if (!chip) {
        perror("Open chip failed");
        return 1;
    }
    
    // Get LED line
    line = gpiod_chip_get_line(chip, LED_PIN);
    if (!line) {
        perror("Get line failed");
        gpiod_chip_close(chip);
        return 1;
    }
    
    // Request output mode
    ret = gpiod_line_request_output(line, "blink", 0);
    if (ret < 0) {
        perror("Request line as output failed");
        gpiod_chip_close(chip);
        return 1;
    }
    
    // Blink 10 times
    printf("Blinking LED 10 times...\n");
    for (int i = 0; i < 10; i++) {
        // LED ON
        gpiod_line_set_value(line, 1);
        printf("LED ON\n");
        sleep(1);
        
        // LED OFF
        gpiod_line_set_value(line, 0);
        printf("LED OFF\n");
        sleep(1);
    }
    
    printf("\nDone!\n");
    
    // Cleanup
    gpiod_line_release(line);
    gpiod_chip_close(chip);
    
    return 0;
}
