#include "sharp_drm.h"
/*
 * Sharp Memory LCD SPI Communication - Enhanced Version
 * Optimized SPI communication with advanced features
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/spi/spi.h>
#include <linux/delay.h>
#include <linux/dma-mapping.h>

extern bool debug;
extern uint spi_speed;

struct sharp_drm_device; /* Forward declaration */

/* Enhanced SPI command function */
int sharp_spi_write_command(struct sharp_drm_device *sdev, u8 cmd)
{
    struct spi_message msg;
    struct spi_transfer xfer = {
        .tx_buf = &cmd,
        .len = 1,
        .speed_hz = sdev->spi_speed,
    };
    int ret;
    
    if (!sdev || !sdev->spi) {
        return -EINVAL;
    }
    
    spi_message_init(&msg);
    spi_message_add_tail(&xfer, &msg);
    
    ret = spi_sync(sdev->spi, &msg);
    if (ret < 0) {
        dev_err(&sdev->spi->dev, "SPI command write failed: %d\n", ret);
    } else if (debug) {
        dev_info(&sdev->spi->dev, "SPI command 0x%02x sent\n", cmd);
    }
    
    return ret;
}

/* Enhanced SPI data transfer with optimization */
int sharp_spi_write_data(struct sharp_drm_device *sdev, const u8 *data, size_t len)
{
    struct spi_message msg;
    struct spi_transfer xfer = {
        .tx_buf = data,
        .len = len,
        .speed_hz = sdev->spi_speed,
    };
    int ret;
    
    if (!sdev || !sdev->spi || !data) {
        return -EINVAL;
    }
    
    if (len > sdev->spi_buf_size) {
        dev_err(&sdev->spi->dev, "Data length %zu exceeds buffer size %zu\n", 
                len, sdev->spi_buf_size);
        return -EINVAL;
    }
    
    spi_message_init(&msg);
    spi_message_add_tail(&xfer, &msg);
    
    ret = spi_sync(sdev->spi, &msg);
    if (ret < 0) {
        dev_err(&sdev->spi->dev, "SPI data write failed: %d\n", ret);
    } else if (debug) {
        dev_info(&sdev->spi->dev, "SPI data written: %zu bytes\n", len);
    }
    
    return ret;
}

/* Optimized bulk transfer for display updates */
int sharp_spi_write_display_bulk(struct sharp_drm_device *sdev, 
                                const u8 *data, size_t len)
{
    struct spi_message msg;
    struct spi_transfer transfers[2] = {
        {
            .tx_buf = &(u8){SHARP_CMD_WRITE},
            .len = 1,
            .speed_hz = sdev->spi_speed,
        },
        {
            .tx_buf = data,
            .len = len,
            .speed_hz = sdev->spi_speed,
        }
    };
    int ret;
    
    if (!sdev || !sdev->spi || !data) {
        return -EINVAL;
    }
    
    spi_message_init(&msg);
    spi_message_add_tail(&transfers[0], &msg);
    spi_message_add_tail(&transfers[1], &msg);
    
    ret = spi_sync(sdev->spi, &msg);
    if (ret < 0) {
        dev_err(&sdev->spi->dev, "SPI bulk write failed: %d\n", ret);
    }
    
    return ret;
}

/* DMA-optimized transfer for large data */
int sharp_spi_write_dma(struct sharp_drm_device *sdev, const u8 *data, size_t len)
{
    struct spi_message msg;
    struct spi_transfer xfer;
    dma_addr_t dma_addr;
    void *dma_buf;
    int ret;
    
    if (!sdev || !sdev->spi || !data) {
        return -EINVAL;
    }
    
    /* Allocate DMA coherent buffer */
    dma_buf = dma_alloc_coherent(&sdev->spi->dev, len, &dma_addr, GFP_KERNEL);
    if (!dma_buf) {
        dev_err(&sdev->spi->dev, "Failed to allocate DMA buffer\n");
        return -ENOMEM;
    }
    
    /* Copy data to DMA buffer */
    memcpy(dma_buf, data, len);
    
    /* Setup transfer */
    memset(&xfer, 0, sizeof(xfer));
    xfer.tx_buf = dma_buf;
    xfer.tx_dma = dma_addr;
    xfer.len = len;
    xfer.speed_hz = sdev->spi_speed;
    
    spi_message_init(&msg);
    spi_message_add_tail(&xfer, &msg);
    
    ret = spi_sync(sdev->spi, &msg);
    
    /* Free DMA buffer */
    dma_free_coherent(&sdev->spi->dev, len, dma_buf, dma_addr);
    
    if (ret < 0) {
        dev_err(&sdev->spi->dev, "SPI DMA write failed: %d\n", ret);
    } else if (debug) {
        dev_info(&sdev->spi->dev, "SPI DMA write completed: %zu bytes\n", len);
    }
    
    return ret;
}

/* Initialize SPI buffers */
int sharp_spi_init_buffers(struct sharp_drm_device *sdev)
{
    size_t buf_size = (sdev->width * sdev->height + 7) / 8;
    
    /* Add some extra space for commands and alignment */
    sdev->spi_buf_size = buf_size + 16;
    
    sdev->spi_tx_buf = devm_kzalloc(&sdev->spi->dev, sdev->spi_buf_size, GFP_KERNEL);
    if (!sdev->spi_tx_buf) {
        dev_err(&sdev->spi->dev, "Failed to allocate SPI TX buffer\n");
        return -ENOMEM;
    }
    
    sdev->spi_rx_buf = devm_kzalloc(&sdev->spi->dev, sdev->spi_buf_size, GFP_KERNEL);
    if (!sdev->spi_rx_buf) {
        dev_err(&sdev->spi->dev, "Failed to allocate SPI RX buffer\n");
        return -ENOMEM;
    }
    
    if (debug) {
        dev_info(&sdev->spi->dev, "SPI buffers initialized: %zu bytes each\n", 
                sdev->spi_buf_size);
    }
    
    return 0;
}

/* Cleanup SPI buffers */
void sharp_spi_cleanup_buffers(struct sharp_drm_device *sdev)
{
    /* Buffers are automatically freed by devm */
    sdev->spi_tx_buf = NULL;
    sdev->spi_rx_buf = NULL;
    sdev->spi_buf_size = 0;
}

/* Configure SPI parameters */
int sharp_spi_configure(struct sharp_drm_device *sdev)
{
    int ret;
    
    if (!sdev || !sdev->spi) {
        return -EINVAL;
    }
    
    /* Set SPI mode */
    sdev->spi->mode = SPI_MODE_0 | SPI_CS_HIGH;
    sdev->spi->bits_per_word = 8;
    sdev->spi->max_speed_hz = min((u32)spi_speed, (u32)MAX_SPI_SPEED);
    
    /* Store the actual speed we'll use */
    sdev->spi_speed = sdev->spi->max_speed_hz;
    
    ret = spi_setup(sdev->spi);
    if (ret) {
        dev_err(&sdev->spi->dev, "SPI setup failed: %d\n", ret);
        return ret;
    }
    
    if (debug) {
        dev_info(&sdev->spi->dev, 
                "SPI configured: mode=0x%x, speed=%u Hz, bpw=%u\n",
                sdev->spi->mode, sdev->spi_speed, sdev->spi->bits_per_word);
    }
    
    return 0;
}

/* Test SPI communication */
int sharp_spi_test_communication(struct sharp_drm_device *sdev)
{
    int ret;
    u8 test_data[] = {0x00, 0x55, 0xAA, 0xFF};
    int i;
    
    if (!sdev || !sdev->spi) {
        return -EINVAL;
    }
    
    dev_info(&sdev->spi->dev, "Testing SPI communication...\n");
    
    for (i = 0; i < ARRAY_SIZE(test_data); i++) {
        ret = sharp_spi_write_command(sdev, test_data[i]);
        if (ret) {
            dev_err(&sdev->spi->dev, "SPI test failed at pattern 0x%02x: %d\n", 
                    test_data[i], ret);
            return ret;
        }
        usleep_range(100, 200);
    }
    
    dev_info(&sdev->spi->dev, "SPI communication test passed\n");
    return 0;
}

/* Get SPI statistics */
void sharp_spi_get_stats(struct sharp_drm_device *sdev, 
                        u64 *total_bytes, u64 *total_transfers)
{
    if (sdev && total_bytes && total_transfers) {
        *total_bytes = sdev->total_spi_bytes;
        *total_transfers = sdev->total_spi_transfers;
    }
}

/* Reset SPI statistics */
void sharp_spi_reset_stats(struct sharp_drm_device *sdev)
{
    if (sdev) {
        sdev->total_spi_bytes = 0;
        sdev->total_spi_transfers = 0;
    }
}
