/*
 * Sharp Memory LCD DRM Driver - Enhanced Version
 * Common definitions and structures
 */

#ifndef __SHARP_DRM_H__
#define __SHARP_DRM_H__

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/gpio/consumer.h>
#include <linux/spi/spi.h>
#include <linux/regulator/consumer.h>
#include <linux/workqueue.h>
#include <linux/timer.h>
#include <linux/mutex.h>
#include <linux/ktime.h>
#include <drm/drm_device.h>
#include <drm/drm_simple_kms_helper.h>
#include <drm/drm_connector.h>
#include <drm/drm_modes.h>

/* Sharp Memory LCD Commands */
#define SHARP_CMD_WRITE 0x80
#define SHARP_CMD_VCOM 0x40
#define SHARP_CMD_CLEAR 0x20

/* Default display parameters */
#define DEFAULT_WIDTH 400
#define DEFAULT_HEIGHT 240
#define MAX_SPI_SPEED 8000000
#define DEFAULT_SPI_SPEED 4000000

/* Power management states */
enum sharp_power_state {
    SHARP_POWER_OFF = 0,
    SHARP_POWER_STANDBY,
    SHARP_POWER_ON
};

/* Enhanced driver structure */
struct sharp_drm_device {
    struct drm_device *drm_device;  /* Pointer to allocated DRM device */
    struct drm_simple_display_pipe pipe;
    struct drm_connector connector;
    struct drm_display_mode mode;
    
    struct spi_device *spi;
    struct gpio_desc *vcom_gpio;
    struct gpio_desc *disp_gpio;
    struct gpio_desc *backlit_gpio;
    struct gpio_desc *reset_gpio;
    struct gpio_desc *button_gpio;  /* GPIO 17 button for backlight toggle */
    
    struct regulator *vdd_supply;
    struct regulator *vddio_supply;
    
    /* Enhanced features */
    struct delayed_work power_save_work;
    struct timer_list vcom_timer;
    struct mutex lock;
    
    /* Display parameters */
    u32 width;
    u32 height;
    u32 line_length;
    u32 bpp;
    u32 refresh_rate;
    
    /* SPI optimization */
    u32 spi_speed;
    u8 *spi_tx_buf;
    u8 *spi_rx_buf;
    size_t spi_buf_size;
    
    /* Power management */
    enum sharp_power_state power_state;
    bool auto_power_save;
    u32 idle_timeout_ms;
    
    /* Display state */
    bool display_on;
    bool backlight_on;
    int button_irq;                  /* IRQ for button GPIO */
    bool button_state;               /* Last button state */
    unsigned long button_debounce;   /* Button debounce timestamp */
    bool vcom_state;
    u32 frame_count;
    
    /* Enhanced parameters */
    u8 mono_cutoff;
    bool mono_invert;
    bool auto_clear;
    u8 dither_mode;
    bool overlays_enabled;
    
    /* Performance monitoring */
    ktime_t last_update;
    u64 total_updates;
    u64 avg_update_time_ns;
    u64 total_spi_bytes;
    u64 total_spi_transfers;
};

/* Utility functions */
static inline struct sharp_drm_device *pipe_to_sharp(struct drm_simple_display_pipe *pipe)
{
    return container_of(pipe, struct sharp_drm_device, pipe);
}

/* External variable declarations */
extern bool debug;
extern bool auto_clear;
extern bool backlit;
extern bool mono_invert;
extern uint mono_cutoff;
extern uint dither_mode;
extern uint spi_speed;
extern bool auto_power_save;
extern uint idle_timeout;

/* Function declarations */
int sharp_drm_init_drm_device(struct sharp_drm_device *sdev);
void sharp_drm_cleanup_drm_device(struct sharp_drm_device *sdev);
int sharp_drm_power_init(struct sharp_drm_device *sdev);
void sharp_drm_power_cleanup(struct sharp_drm_device *sdev);
int sharp_drm_power_on(struct sharp_drm_device *sdev);
int sharp_drm_power_off(struct sharp_drm_device *sdev);
void sharp_drm_power_update_activity(struct sharp_drm_device *sdev);
int sharp_spi_configure(struct sharp_drm_device *sdev);
int sharp_spi_init_buffers(struct sharp_drm_device *sdev);
void sharp_spi_cleanup_buffers(struct sharp_drm_device *sdev);
int sharp_spi_write_command(struct sharp_drm_device *sdev, u8 cmd);
int sharp_spi_write_data(struct sharp_drm_device *sdev, const u8 *data, size_t len);
void sharp_drm_update_display(struct sharp_drm_device *sdev, struct drm_framebuffer *fb);
void sharp_drm_clear_display(struct sharp_drm_device *sdev);
void sharp_drm_toggle_vcom(struct sharp_drm_device *sdev);
void sharp_drm_set_backlight(struct sharp_drm_device *sdev, bool on);

#define sharp_debug(sdev, fmt, ...) \
    do { \
        if (debug) \
            dev_info(&(sdev)->spi->dev, fmt, ##__VA_ARGS__); \
    } while (0)

#endif /* __SHARP_DRM_H__ */

/* Test and debug functions */
void sharp_drm_test_pattern(struct sharp_drm_device *sdev, int pattern);

