#include <linux/types.h>
#include <linux/module.h>
#include <linux/moduleparam.h>

#include "params_iface.h"
#include "drm_iface.h"

unsigned char g_param_color_cutoff = 127;
unsigned char g_param_mono_cutoff = 32;
bool g_param_mono_invert = false;
bool g_param_overlays = true;
bool g_param_auto_clear = true;
bool g_param_color = true;
bool g_param_backlit = false;  // Nuevo parámetro backlit - inicializado en OFF

/* Power saving parameters */
bool g_param_auto_power_save = false;
uint g_param_idle_timeout = 30000; /* 30 seconds */

/* Dithering parameter */
uint g_param_dither = 0;

module_param_named(color_cutoff, g_param_color_cutoff, byte, 0660);
MODULE_PARM_DESC(color_cutoff,
	"Color value from 0-255 after which color pixels will be activated");

module_param_named(mono_cutoff, g_param_mono_cutoff, byte, 0660);
MODULE_PARM_DESC(mono_cutoff,
	"Greyscale value from 0-255 after which a mono pixel will be activated");

module_param_named(mono_invert, g_param_mono_invert, bool, 0660);
MODULE_PARM_DESC(mono_invert, "0 for no inversion, 1 for inversion");

module_param_named(overlays, g_param_overlays, bool, 0660);
MODULE_PARM_DESC(overlays, "0 for no overlays, 1 for overlays");

module_param_named(auto_clear, g_param_auto_clear, bool, 0660);
MODULE_PARM_DESC(auto_clear, "0 to retain screen contents on driver unload, 1 to clear");

module_param_named(color, g_param_color, bool, 0660);
MODULE_PARM_DESC(color, "0 for no color, 1 for color");

module_param_named(backlit, g_param_backlit, bool, 0660);
MODULE_PARM_DESC(backlit, "0 for backlight off, 1 for backlight on");

module_param_named(auto_power_save, g_param_auto_power_save, bool, 0660);
MODULE_PARM_DESC(auto_power_save, "Enable automatic power saving mode");

module_param_named(idle_timeout, g_param_idle_timeout, uint, 0660);
MODULE_PARM_DESC(idle_timeout, "Idle timeout in milliseconds before power save");

module_param_named(dither, g_param_dither, uint, 0660);
MODULE_PARM_DESC(dither, "Dithering mode (0-4)");

int params_probe(void)
{
	return 0;
}

void params_remove(void)
{
	return;
}

void params_set_mono_invert(int setting)
{
	g_param_mono_invert = setting;
}
