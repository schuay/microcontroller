#include <stdint.h>

#define WIDTH (128)
#define HEIGHT (64)
#define PX_PER_LINE (8)
#define PX_PER_CHIP (64)

/**
 * Initializes the microcontroller to interface with the GLCD
 * and initializes the display controllers.
 * After completion, the GLCD screen is empty and ready for use.
 */
uint8_t halGlcdInit(void);

/**
 * Sets up the controller address such that the next read or write
 * will be from (xCol, yPage).
 * @return Returns 0 if successful, 1 if coordinates are out of bounds.
 */
uint8_t halGlcdSetAddress(const uint8_t xCol, const uint8_t yPage);

/**
 * Writes data to the GLCD display RAM.
 * After completion, the controller address points to the next
 * horizontal coordinate, or if EOL has been reached the first pixel of
 * the next line. If the EOL has been reached on the last line, 
 * the address wraps around to (0, 0).
 * @return Returns 0.
 */
uint8_t halGlcdWriteData(const uint8_t data);

/**
 * Reads data from the GLCD display RAM.
 * After completion, the controller address points to the next
 * horizontal coordinate, or if EOL has been reached the first pixel of
 * the next line. If the EOL has been reached on the last line, 
 * the address wraps around to (0, 0).
 * @return Returns 0.
 */
uint8_t halGlcdReadData(void);

