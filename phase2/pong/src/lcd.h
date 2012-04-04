#ifndef LCD_H
#define LCD_H

void lcd_init(void);
void lcd_putchar(char c, uint8_t row, uint8_t col);
void lcd_clear(void);

#endif /* LCD_H */
