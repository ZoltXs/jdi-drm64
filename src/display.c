#include "sharp_drm.h"

/*
 * Sharp Memory LCD Display Management - Fixed Version
 * Author: N@Xs
 * Corrected for proper JDI LT027B5AC01 400x240 operation
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/spi/spi.h>
#include <linux/ktime.h>

#include <drm/drm_fourcc.h>
#include <drm/drm_fb_dma_helper.h>
#include <drm/drm_gem_dma_helper.h>
#include <drm/drm_framebuffer.h>
extern uint mono_cutoff;
extern bool mono_invert;
extern uint dither_mode;
extern bool debug;

/* JDI/Sharp Memory LCD Commands */
#define JDI_CMD_WRITE_LINE    0x80
#define JDI_CMD_CLEAR_ALL     0x20
#define JDI_CMD_NO_UPDATE     0x00
#define JDI_CMD_VCOM          0x40


/* Convert RGB pixel to 3-bit color for LPM027M128C */
static u8 rgb_to_3bit_color(u32 rgb_pixel)
{
    u8 r = (rgb_pixel >> 16) & 0xFF;
    u8 g = (rgb_pixel >> 8) & 0xFF;
    u8 b = rgb_pixel & 0xFF;
    
    /* Convert each component to 1 bit using threshold */
    u8 r_bit = (r > 127) ? 1 : 0;
    u8 g_bit = (g > 127) ? 1 : 0;
    u8 b_bit = (b > 127) ? 1 : 0;
    
    /* Combine into 3-bit RGB */
    return (r_bit << 2) | (g_bit << 1) | b_bit;
}

/* Convert RGB pixel to monochrome */
static u8 rgb_to_mono_simple(u32 rgb_pixel)
{
    u8 r = (rgb_pixel >> 16) & 0xFF;
    u8 g = (rgb_pixel >> 8) & 0xFF;
    u8 b = rgb_pixel & 0xFF;
    
    /* Convert to grayscale using standard weights */
    u16 gray = (r * 77 + g * 151 + b * 28) >> 8;
    
    /* Apply threshold */
    u8 mono = gray > mono_cutoff ? 1 : 0;
    
    /* Apply inversion if enabled */
    return mono_invert ? !mono : mono;
}


/* Write RGB color line to display using 3-bit mode */
static int jdi_write_color_line(struct sharp_drm_device *sdev, u16 line_num, const u8 *line_data)
{
    struct spi_message msg;
    struct spi_transfer transfers[4];
    u8 cmd = 0x80;  /* Write command */
    u8 line_addr[2];
    u8 dummy = 0x00;
    int ret;
    
    if (!sdev || !line_data || line_num >= sdev->height) {
        return -EINVAL;
    }
    
    memset(transfers, 0, sizeof(transfers));
    
    /* Line address according to LPM027M128C spec */
    line_addr[0] = cmd | ((line_num + 1) & 0x7F);  /* 7-bit LSB */
    line_addr[1] = ((line_num + 1) >> 7) & 0x07;    /* 3-bit MSB */
    
    /* Transfer 0: Command & line address */
    transfers[0].tx_buf = line_addr;
    transfers[0].len = 2;
    
    /* Transfer 1: RGB data (3 bits per pixel) */
    transfers[1].tx_buf = line_data;
    transfers[1].len = (sdev->width * 3 + 7) / 8;  /* 3 bits per pixel */
    
    /* Transfer 2: Dummy byte */
    transfers[2].tx_buf = &dummy;
    transfers[2].len = 1;
    
    spi_message_init(&msg);
    spi_message_add_tail(&transfers[0], &msg);
    spi_message_add_tail(&transfers[1], &msg);
    spi_message_add_tail(&transfers[2], &msg);
    
    ret = spi_sync(sdev->spi, &msg);
    if (ret < 0) {
        dev_err(&sdev->spi->dev, "SPI color line write failed: %d\n", ret);
    }
    
    return ret;
}

/* Write a single line to the display using proper JDI protocol */
static int jdi_write_line(struct sharp_drm_device *sdev, u16 line_num, const u8 *line_data)
{
    struct spi_message msg;
    struct spi_transfer transfers[4];
    u8 cmd = JDI_CMD_WRITE_LINE;
    u8 line_addr = line_num + 1;  /* Lines are 1-indexed */
    u8 dummy = 0x00;
    int ret;
    
    if (!sdev || !line_data || line_num >= sdev->height) {
        return -EINVAL;
    }
    
    memset(transfers, 0, sizeof(transfers));
    
    /* Transfer 0: Command byte */
    transfers[0].tx_buf = &cmd;
    transfers[0].len = 1;
    
    /* Transfer 1: Line address */
    transfers[1].tx_buf = &line_addr;
    transfers[1].len = 1;
    
    /* Transfer 2: Line data */
    transfers[2].tx_buf = line_data;
    transfers[2].len = (sdev->width + 7) / 8;  /* Number of bytes per line */
    
    /* Transfer 3: Dummy byte to complete transaction */
    transfers[3].tx_buf = &dummy;
    transfers[3].len = 1;
    
    spi_message_init(&msg);
    spi_message_add_tail(&transfers[0], &msg);
    spi_message_add_tail(&transfers[1], &msg);
    spi_message_add_tail(&transfers[2], &msg);
    spi_message_add_tail(&transfers[3], &msg);
    
    ret = spi_sync(sdev->spi, &msg);
    if (ret < 0) {
        dev_err(&sdev->spi->dev, "SPI line write failed: %d\n", ret);
    }
    
    return ret;
}

/* Clear entire display using JDI clear command */
void sharp_drm_clear_display(struct sharp_drm_device *sdev)
{
    struct spi_message msg;
    struct spi_transfer transfers[2];
    u8 cmd = JDI_CMD_CLEAR_ALL;
    u8 dummy = 0x00;
    int ret;
    
    if (!sdev) {
        return;
    }
    
    if (debug) {
        dev_info(&sdev->spi->dev, "Clearing display\n");
    }
    
    mutex_lock(&sdev->lock);
    
    memset(transfers, 0, sizeof(transfers));
    
    /* Transfer 0: Clear command */
    transfers[0].tx_buf = &cmd;
    transfers[0].len = 1;
    
    /* Transfer 1: Dummy byte */
    transfers[1].tx_buf = &dummy;
    transfers[1].len = 1;
    
    spi_message_init(&msg);
    spi_message_add_tail(&transfers[0], &msg);
    spi_message_add_tail(&transfers[1], &msg);
    
    ret = spi_sync(sdev->spi, &msg);
    if (ret < 0) {
        dev_err(&sdev->spi->dev, "Display clear failed: %d\n", ret);
    } else if (debug) {
        dev_info(&sdev->spi->dev, "Display cleared successfully\n");
    }
    
    mutex_unlock(&sdev->lock);
}

/* Main display update function - COMPLETELY REWRITTEN for JDI */
void sharp_drm_update_display(struct sharp_drm_device *sdev, struct drm_framebuffer *fb)
{
    struct drm_gem_dma_object *cma_obj;
    void *vaddr;
    u32 *fb_pixels;
    u8 *line_buffer;
    u32 width, height, pitch;
    int x, y;
    int bytes_per_line;
    ktime_t start_time, end_time;
    int ret = 0;
    
    if (!sdev || !fb) {
        return;
    }
    
    /* Check if display is powered on */
    if (sdev->power_state != SHARP_POWER_ON) {
        if (debug) {
            dev_warn(&sdev->spi->dev, "Display not powered on, skipping update\n");
        }
        return;
    }
    
    start_time = ktime_get();
    
    /* Get framebuffer data */
    cma_obj = drm_fb_dma_get_gem_obj(fb, 0);
    if (!cma_obj || !cma_obj->vaddr) {
        dev_err(&sdev->spi->dev, "No framebuffer data available\n");
        return;
    }
    
    vaddr = cma_obj->vaddr;
    width = fb->width;
    height = fb->height;
    pitch = fb->pitches[0];
    
    /* Limit to display dimensions */
    width = min(width, sdev->width);
    height = min(height, sdev->height);
    
    bytes_per_line = (width + 7) / 8;
    
    /* Allocate line buffer */
    line_buffer = kzalloc(bytes_per_line, GFP_KERNEL);
    if (!line_buffer) {
        dev_err(&sdev->spi->dev, "Failed to allocate line buffer\n");
        return;
    }
    
    mutex_lock(&sdev->lock);
    
    /* Process each line separately - this is the key fix! */
    for (y = 0; y < height; y++) {
        /* Clear line buffer */
        memset(line_buffer, 0, bytes_per_line);
        
        /* Convert one line from RGB to monochrome */
        for (x = 0; x < width; x++) {
            u32 pixel = 0;
            u8 mono_pixel;
            int byte_idx = x / 8;
            int bit_idx = 7 - (x % 8);
            
            /* Extract pixel based on format */
            switch (fb->format->format) {
            case DRM_FORMAT_XRGB8888:
            case DRM_FORMAT_ARGB8888:
                fb_pixels = (u32 *)(vaddr + y * pitch);
                pixel = fb_pixels[x] & 0xFFFFFF; /* Remove alpha */
                break;
                
            case DRM_FORMAT_RGB565:
                {
                    u16 *fb_pixels16 = (u16 *)(vaddr + y * pitch);
                    u16 rgb565 = fb_pixels16[x];
                    u8 r = ((rgb565 >> 11) & 0x1F) * 255 / 31;
                    u8 g = ((rgb565 >> 5) & 0x3F) * 255 / 63;
                    u8 b = (rgb565 & 0x1F) * 255 / 31;
                    pixel = (r << 16) | (g << 8) | b;
                }
                break;
                
            default:
                /* Assume grayscale */
                {
                    u8 *fb_pixels8 = (u8 *)(vaddr + y * pitch);
                    u8 gray = fb_pixels8[x];
                    pixel = (gray << 16) | (gray << 8) | gray;
                }
                break;
            }
            
            /* Convert to monochrome */
            mono_pixel = rgb_to_mono_simple(pixel);
            
            /* Set bit in line buffer */
            if (mono_pixel) {
                line_buffer[byte_idx] |= (1 << bit_idx);
            }
        }
        
        /* Send this line to the display */
        ret = jdi_write_line(sdev, y, line_buffer);
        if (ret < 0) {
            dev_err(&sdev->spi->dev, "Failed to write line %d: %d\n", y, ret);
            break;
        }
        
        /* Small delay between lines for stability */
        if (y % 40 == 0) {
            usleep_range(100, 200);
        }
    }
    
    mutex_unlock(&sdev->lock);
    
    kfree(line_buffer);
    
    /* Update statistics */
    if (ret >= 0) {
        sdev->frame_count++;
        end_time = ktime_get();
        
        if (debug) {
            u64 update_time_ns = ktime_to_ns(ktime_sub(end_time, start_time));
            dev_info(&sdev->spi->dev, "Display updated: frame %u, time %llu ns\n",
                    sdev->frame_count, update_time_ns);
        }
    }
}

/* Toggle VCOM signal - this is CRITICAL for Sharp Memory LCDs */
void sharp_drm_toggle_vcom(struct sharp_drm_device *sdev)
{
    if (!sdev) {
        return;
    }
    
    /* Toggle VCOM state */
    sdev->vcom_state = !sdev->vcom_state;
    
    /* Set GPIO if available */
    if (sdev->vcom_gpio) {
        gpiod_set_value_cansleep(sdev->vcom_gpio, sdev->vcom_state);
    }
    
    /* Send VCOM toggle via SPI as well */
    if (sdev->power_state == SHARP_POWER_ON) {
        struct spi_message msg;
        struct spi_transfer transfers[2];
        u8 cmd = JDI_CMD_VCOM | (sdev->vcom_state ? 0x40 : 0x00);
        u8 dummy = 0x00;
        
        memset(transfers, 0, sizeof(transfers));
        
        transfers[0].tx_buf = &cmd;
        transfers[0].len = 1;
        
        transfers[1].tx_buf = &dummy;
        transfers[1].len = 1;
        
        spi_message_init(&msg);
        spi_message_add_tail(&transfers[0], &msg);
        spi_message_add_tail(&transfers[1], &msg);
        
        mutex_lock(&sdev->lock);
        spi_sync(sdev->spi, &msg);
        mutex_unlock(&sdev->lock);
    }
    
    if (debug && (sdev->frame_count % 60 == 0)) {
        dev_info(&sdev->spi->dev, "VCOM toggled to %d\n", sdev->vcom_state);
    }
}

/* Set backlight state */
void sharp_drm_set_backlight(struct sharp_drm_device *sdev, bool on)
{
    if (!sdev) {
        return;
    }
    
    if (sdev->backlit_gpio) {
        gpiod_set_value_cansleep(sdev->backlit_gpio, on);
        sdev->backlight_on = on;
        
        if (debug) {
            dev_info(&sdev->spi->dev, "Backlight %s\n", on ? "on" : "off");
        }
    }
}

/* Test pattern generator for debugging */
void sharp_drm_test_pattern(struct sharp_drm_device *sdev, int pattern)
{
    u8 *line_buffer;
    int bytes_per_line;
    int y, x;
    
    if (!sdev || sdev->power_state != SHARP_POWER_ON) {
        return;
    }
    
    bytes_per_line = (sdev->width + 7) / 8;
    line_buffer = kzalloc(bytes_per_line, GFP_KERNEL);
    if (!line_buffer) {
        return;
    }
    
    dev_info(&sdev->spi->dev, "Generating test pattern %d\n", pattern);
    
    mutex_lock(&sdev->lock);
    
    for (y = 0; y < sdev->height; y++) {
        memset(line_buffer, 0, bytes_per_line);
        
        switch (pattern) {
        case 0: /* All white */
            memset(line_buffer, 0xFF, bytes_per_line);
            break;
            
        case 1: /* Horizontal stripes */
            if (y % 2 == 0) {
                memset(line_buffer, 0xFF, bytes_per_line);
            }
            break;
            
        case 2: /* Vertical stripes */
            for (x = 0; x < sdev->width; x += 2) {
                int byte_idx = x / 8;
                int bit_idx = 7 - (x % 8);
                if (byte_idx < bytes_per_line) {
                    line_buffer[byte_idx] |= (1 << bit_idx);
                }
            }
            break;
            
        case 3: /* Checkerboard */
            for (x = 0; x < sdev->width; x++) {
                if ((x + y) % 2 == 0) {
                    int byte_idx = x / 8;
                    int bit_idx = 7 - (x % 8);
                    if (byte_idx < bytes_per_line) {
                        line_buffer[byte_idx] |= (1 << bit_idx);
                    }
                }
            }
            break;
            
        default: /* Border */
            if (y == 0 || y == sdev->height - 1) {
                memset(line_buffer, 0xFF, bytes_per_line);
            } else {
                line_buffer[0] |= 0x80; /* Left border */
                if (bytes_per_line > 1) {
                    int last_byte = bytes_per_line - 1;
                    int last_bit = 7 - ((sdev->width - 1) % 8);
                    line_buffer[last_byte] |= (1 << last_bit); /* Right border */
                }
            }
            break;
        }
        
        jdi_write_line(sdev, y, line_buffer);
        
        if (y % 20 == 0) {
            usleep_range(100, 200);
        }
    }
    
    mutex_unlock(&sdev->lock);
    kfree(line_buffer);
    
    dev_info(&sdev->spi->dev, "Test pattern %d complete\n", pattern);
}
