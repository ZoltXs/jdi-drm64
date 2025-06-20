#include "sharp_drm.h"
/*
 * Sharp Memory LCD Power Management - Enhanced Version
 * Advanced power management with energy saving features
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/regulator/consumer.h>
#include <linux/pm_runtime.h>
#include <linux/workqueue.h>
#include <linux/timer.h>

extern bool debug;
extern bool g_param_auto_power_save;
#define auto_power_save g_param_auto_power_save
extern uint g_param_idle_timeout;
#define idle_timeout g_param_idle_timeout

struct sharp_drm_device; /* Forward declaration */

/* Power state management */
int sharp_drm_power_on(struct sharp_drm_device *sdev)
{
    int ret = 0;
    
    if (sdev->power_state == SHARP_POWER_ON)
        return 0;
        
    if (debug) {
        dev_info(&sdev->spi->dev, "Powering on display\n");
    }
    
    /* Enable power supplies if available */
    if (sdev->vdd_supply) {
        ret = regulator_enable(sdev->vdd_supply);
        if (ret) {
            dev_err(&sdev->spi->dev, "Failed to enable VDD supply: %d\n", ret);
            return ret;
        }
    }
    
    if (sdev->vddio_supply) {
        ret = regulator_enable(sdev->vddio_supply);
        if (ret) {
            dev_err(&sdev->spi->dev, "Failed to enable VDDIO supply: %d\n", ret);
            goto err_vddio;
        }
    }
    
    /* Small delay for power stabilization */
    usleep_range(1000, 2000);
    
    /* Release reset if available */
    if (sdev->reset_gpio) {
        gpiod_set_value(sdev->reset_gpio, 0);
        usleep_range(1000, 2000);
    }
    
    /* Enable display */
    if (sdev->disp_gpio) {
        gpiod_set_value(sdev->disp_gpio, 1);
        sdev->display_on = true;
    }
    
    /* Enable backlight if requested */
    if (sdev->backlit_gpio && backlit) {
        gpiod_set_value(sdev->backlit_gpio, 1);
        sdev->backlight_on = true;
    }
    
    /* Start VCOM timer */
    if (timer_pending(&sdev->vcom_timer)) {
        del_timer(&sdev->vcom_timer);
    }
    mod_timer(&sdev->vcom_timer, jiffies + msecs_to_jiffies(1000));
    
    sdev->power_state = SHARP_POWER_ON;
    
    if (debug) {
        dev_info(&sdev->spi->dev, "Display powered on successfully\n");
    }
    
    return 0;
    
err_vddio:
    if (sdev->vdd_supply)
        regulator_disable(sdev->vdd_supply);
    return ret;
}

int sharp_drm_power_off(struct sharp_drm_device *sdev)
{
    if (sdev->power_state == SHARP_POWER_OFF)
        return 0;
        
    if (debug) {
        dev_info(&sdev->spi->dev, "Powering off display\n");
    }
    
    /* Stop VCOM timer */
    del_timer_sync(&sdev->vcom_timer);
    
    /* Clear display if auto_clear is enabled */
    if (auto_clear && sdev->power_state == SHARP_POWER_ON) {
        sharp_drm_clear_display(sdev);
    }
    
    /* Disable backlight */
    if (sdev->backlit_gpio) {
        gpiod_set_value(sdev->backlit_gpio, 0);
        sdev->backlight_on = false;
    }
    
    /* Disable display */
    if (sdev->disp_gpio) {
        gpiod_set_value(sdev->disp_gpio, 0);
        sdev->display_on = false;
    }
    
    /* Assert reset if available */
    if (sdev->reset_gpio) {
        gpiod_set_value(sdev->reset_gpio, 1);
    }
    
    /* Disable power supplies */
    if (sdev->vddio_supply)
        regulator_disable(sdev->vddio_supply);
    if (sdev->vdd_supply)
        regulator_disable(sdev->vdd_supply);
    
    sdev->power_state = SHARP_POWER_OFF;
    
    if (debug) {
        dev_info(&sdev->spi->dev, "Display powered off\n");
    }
    
    return 0;
}

/* Standby mode for power saving */
int sharp_drm_power_standby(struct sharp_drm_device *sdev)
{
    if (sdev->power_state == SHARP_POWER_STANDBY)
        return 0;
        
    if (debug) {
        dev_info(&sdev->spi->dev, "Entering standby mode\n");
    }
    
    /* Stop VCOM timer to save power */
    del_timer_sync(&sdev->vcom_timer);
    
    /* Disable backlight to save power */
    if (sdev->backlit_gpio && sdev->backlight_on) {
        gpiod_set_value(sdev->backlit_gpio, 0);
    }
    
    /* Keep display enabled but reduce refresh rate */
    sdev->power_state = SHARP_POWER_STANDBY;
    
    return 0;
}

/* Resume from standby */
int sharp_drm_power_resume(struct sharp_drm_device *sdev)
{
    if (sdev->power_state != SHARP_POWER_STANDBY)
        return 0;
        
    if (debug) {
        dev_info(&sdev->spi->dev, "Resuming from standby\n");
    }
    
    /* Restore backlight if it was on before */
    if (sdev->backlit_gpio && backlit) {
        gpiod_set_value(sdev->backlit_gpio, 1);
    }
    
    /* Restart VCOM timer */
    mod_timer(&sdev->vcom_timer, jiffies + msecs_to_jiffies(1000));
    
    sdev->power_state = SHARP_POWER_ON;
    
    return 0;
}

/* Auto power save work function */
static void sharp_auto_power_save_work(struct work_struct *work)
{
    struct sharp_drm_device *sdev = container_of(work, struct sharp_drm_device, 
                                                power_save_work.work);
    ktime_t now = ktime_get();
    u64 idle_time_ms;
    
    if (!auto_power_save || sdev->power_state != SHARP_POWER_ON)
        return;
    
    idle_time_ms = ktime_to_ms(ktime_sub(now, sdev->last_update));
    
    if (idle_time_ms > idle_timeout) {
        if (debug) {
            dev_info(&sdev->spi->dev, 
                    "Auto power save: idle for %llu ms, entering standby\n", 
                    idle_time_ms);
        }
        sharp_drm_power_standby(sdev);
    } else {
        /* Schedule next check */
        schedule_delayed_work(&sdev->power_save_work, 
                            msecs_to_jiffies(idle_timeout / 4));
    }
}

/* Initialize power management */
int sharp_drm_power_init(struct sharp_drm_device *sdev)
{
    /* Initialize power save work */
    INIT_DELAYED_WORK(&sdev->power_save_work, sharp_auto_power_save_work);
    
    /* Get optional power supplies */
    sdev->vdd_supply = devm_regulator_get_optional(&sdev->spi->dev, "vdd");
    if (IS_ERR(sdev->vdd_supply)) {
        if (PTR_ERR(sdev->vdd_supply) == -EPROBE_DEFER)
            return -EPROBE_DEFER;
        sdev->vdd_supply = NULL;
    }
    
    sdev->vddio_supply = devm_regulator_get_optional(&sdev->spi->dev, "vddio");
    if (IS_ERR(sdev->vddio_supply)) {
        if (PTR_ERR(sdev->vddio_supply) == -EPROBE_DEFER)
            return -EPROBE_DEFER;
        sdev->vddio_supply = NULL;
    }
    
    /* Set initial power state */
    sdev->power_state = SHARP_POWER_OFF;
    sdev->idle_timeout_ms = idle_timeout;
    sdev->auto_power_save = auto_power_save;
    
    return 0;
}

/* Cleanup power management */
void sharp_drm_power_cleanup(struct sharp_drm_device *sdev)
{
    /* Cancel any pending power save work */
    cancel_delayed_work_sync(&sdev->power_save_work);
    
    /* Power off the display */
    sharp_drm_power_off(sdev);
}

/* Start auto power save monitoring */
void sharp_drm_power_start_monitor(struct sharp_drm_device *sdev)
{
    if (auto_power_save && sdev->power_state == SHARP_POWER_ON) {
        schedule_delayed_work(&sdev->power_save_work, 
                            msecs_to_jiffies(idle_timeout / 4));
    }
}

/* Stop auto power save monitoring */
void sharp_drm_power_stop_monitor(struct sharp_drm_device *sdev)
{
    cancel_delayed_work_sync(&sdev->power_save_work);
}

/* Update activity timestamp */
void sharp_drm_power_update_activity(struct sharp_drm_device *sdev)
{
    sdev->last_update = ktime_get();
    
    /* Resume from standby if needed */
    if (sdev->power_state == SHARP_POWER_STANDBY) {
        sharp_drm_power_resume(sdev);
    }
    
    /* Restart power save monitoring */
    if (auto_power_save) {
        cancel_delayed_work(&sdev->power_save_work);
        schedule_delayed_work(&sdev->power_save_work, 
                            msecs_to_jiffies(idle_timeout / 4));
    }
}
