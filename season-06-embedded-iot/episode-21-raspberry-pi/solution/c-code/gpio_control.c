/*
 * GPIO Control Program - Episode 21 SOLUTION
 * KERNEL SHADOWS
 * 
 * Mission: Control LED via GPIO for surveillance system
 */

#include <gpiod.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>

#define GPIO_CHIP "gpiochip0"
#define LED_PIN 17  // GPIO 17 (Physical pin 11)

// Global for signal handling
static struct gpiod_line *global_line = NULL;
static struct gpiod_chip *global_chip = NULL;

void cleanup_gpio(int sig) {
    printf("\n\nCleaning up GPIO...\n");
    if (global_line) {
        gpiod_line_set_value(global_line, 0);  // LED OFF
        gpiod_line_release(global_line);
    }
    if (global_chip) {
        gpiod_chip_close(global_chip);
    }
    exit(0);
}

int main(int argc, char *argv[]) {
    struct gpiod_chip *chip;
    struct gpiod_line *line;
    int ret;
    int blink_count = 5;
    
    printf("=== GPIO LED Control - Episode 21 ===\n");
    printf("Mission: Surveillance system signal\n\n");
    
    // Setup signal handler
    signal(SIGINT, cleanup_gpio);
    signal(SIGTERM, cleanup_gpio);
    
    // Open GPIO chip
    chip = gpiod_chip_open_by_name(GPIO_CHIP);
    if (!chip) {
        perror("Failed to open GPIO chip");
        fprintf(stderr, "Make sure running on Raspberry Pi\n");
        return 1;
    }
    global_chip = chip;
    printf("✓ GPIO chip opened\n");
    
    // Get GPIO line for LED
    line = gpiod_chip_get_line(chip, LED_PIN);
    if (!line) {
        perror("Failed to get GPIO line");
        gpiod_chip_close(chip);
        return 1;
    }
    global_line = line;
    printf("✓ GPIO line %d acquired\n", LED_PIN);
    
    // Request line as output
    ret = gpiod_line_request_output(line, "gpio_control", 0);
    if (ret < 0) {
        perror("Failed to request line as output");
        fprintf(stderr, "Try running with sudo\n");
        gpiod_chip_close(chip);
        return 1;
    }
    printf("✓ GPIO configured as output\n\n");
    
    // Blink LED
    printf("Blinking LED %d times for signal...\n", blink_count);
    
    for (int i = 0; i < blink_count; i++) {
        // LED ON
        ret = gpiod_line_set_value(line, 1);
        if (ret < 0) {
            perror("Failed to set GPIO HIGH");
            break;
        }
        printf("  [%d] LED ON\n", i + 1);
        sleep(1);
        
        // LED OFF
        ret = gpiod_line_set_value(line, 0);
        if (ret < 0) {
            perror("Failed to set GPIO LOW");
            break;
        }
        printf("  [%d] LED OFF\n", i + 1);
        sleep(1);
    }
    
    printf("\n✓ Signal complete!\n");
    
    // Cleanup
    gpiod_line_release(line);
    gpiod_chip_close(chip);
    printf("✓ GPIO resources released\n");
    
    return 0;
}
