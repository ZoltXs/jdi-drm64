#ifndef PARAMS_IFACE_H_
#define PARAMS_IFACE_H_

extern unsigned char g_param_color_cutoff;
extern unsigned char g_param_mono_cutoff;
extern bool g_param_mono_invert;
extern bool g_param_overlays;
extern bool g_param_auto_clear;
extern bool g_param_color;
extern bool g_param_backlit;  // Nuevo parámetro backlit
extern bool g_param_auto_power_save;
extern uint g_param_idle_timeout;
extern uint g_param_dither;

int params_probe(void);
void params_remove(void);

void params_set_mono_invert(int setting);

#endif
extern uint g_param_dither;
