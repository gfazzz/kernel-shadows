/*
 * GPIO Control Program - Episode 21
 * KERNEL SHADOWS
 * 
 * Mission: Control LED via GPIO for surveillance system
 * 
 * TODO: Complete the TODOs below
 */

#include <gpiod.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#define GPIO_CHIP "gpiochip0"
#define LED_PIN 17  // GPIO 17 (Physical pin 11)

int main(int argc, char *argv[]) {
    struct gpiod_chip *chip;
    struct gpiod_line *line;
    int ret;
    int blink_count = 5;
    
    printf("=== GPIO LED Control - Episode 21 ===\n");
    printf("Mission: Surveillance system signal\n\n");
    
    // TODO 1: Open GPIO chip
    // Hint: Use gpiod_chip_open_by_name()
    chip = NULL;  // <-- Replace with actual code
    
    if (!chip) {
        perror("Failed to open GPIO chip");
        return 1;
    }
    
    printf("✓ GPIO chip opened\n");
    
    // TODO 2: Get GPIO line for LED
    // Hint: Use gpiod_chip_get_line()
    line = NULL;  // <-- Replace with actual code
    
    if (!line) {
        perror("Failed to get GPIO line");
        gpiod_chip_close(chip);
        return 1;
    }
    
    printf("✓ GPIO line %d acquired\n", LED_PIN);
    
    // TODO 3: Request line as output
    // Hint: Use gpiod_line_request_output()
    // Parameters: line, consumer_name, initial_value
    ret = -1;  // <-- Replace with actual code
    
    if (ret < 0) {
        perror("Failed to request line as output");
        gpiod_chip_close(chip);
        return 1;
    }
    
    printf("✓ GPIO configured as output\n\n");
    
    // TODO 4: Blink LED
    printf("Blinking LED %d times for signal...\n", blink_count);
    
    for (int i = 0; i < blink_count; i++) {
        // TODO: Set GPIO HIGH (LED ON)
        // Hint: gpiod_line_set_value(line, 1);
        
        printf("  [%d] LED ON\n", i + 1);
        sleep(1);
        
        // TODO: Set GPIO LOW (LED OFF)
        // Hint: gpiod_line_set_value(line, 0);
        
        printf("  [%d] LED OFF\n", i + 1);
        sleep(1);
    }
    
    printf("\n✓ Signal complete!\n");
    
    // TODO 5: Cleanup
    // Hint: Release line and close chip
    // gpiod_line_release(line);
    // gpiod_chip_close(chip);
    
    printf("✓ GPIO resources released\n");
    
    return 0;
}
