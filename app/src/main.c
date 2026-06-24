/*
 * LED + Relay demo:
 *  - Green LEDs (LED2-LED5, GPIOG): sequential chase at 200 ms each
 *  - RGB LED (PD8=R, PD9=G, PD10=B): cycles through 8 colors at 700 ms each
 *  - Relays (RS1-RS4_2, PG10-PG15): all toggle together every 1 second
 *    → Enable by uncommenting #define ENABLE_RELAYS below.
 */
#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>

/* ── Relay feature flag ─────────────────────────────────────────────────────
 * Uncomment the line below to activate relay switching.
 * Leave it commented to keep all relay GPIOs inactive.
 * ─────────────────────────────────────────────────────────────────────────── */
// #define ENABLE_RELAYS

/* Green status LEDs */
static const struct gpio_dt_spec leds[] = {
    GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(led3), gpios),
};

/* RGB LED channels: index 0=R, 1=G, 2=B */
static const struct gpio_dt_spec rgb[] = {
    GPIO_DT_SPEC_GET(DT_ALIAS(ledr), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(ledg), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(ledb), gpios),
};

/* Color table {R, G, B} */
static const uint8_t colors[][3] = {
    {1, 0, 0},  /* Red     */
    {0, 1, 0},  /* Green   */
    {0, 0, 1},  /* Blue    */
    {1, 1, 0},  /* Yellow  */
    {0, 1, 1},  /* Cyan    */
    {1, 0, 1},  /* Magenta */
    {1, 1, 1},  /* White   */
    {0, 0, 0},  /* Off     */
};

static void set_color(int c)
{
    gpio_pin_set_dt(&rgb[0], colors[c][0]);
    gpio_pin_set_dt(&rgb[1], colors[c][1]);
    gpio_pin_set_dt(&rgb[2], colors[c][2]);
}

/* RGB thread: cycles through colors every 700 ms */
#define RGB_STACK 512
K_THREAD_STACK_DEFINE(rgb_stack, RGB_STACK);
static struct k_thread rgb_tid;

static void rgb_thread(void *p1, void *p2, void *p3)
{
    int c = 0;

    while (1) {
        set_color(c);
        c = (c + 1) % ARRAY_SIZE(colors);
        k_msleep(700);
    }
}

/* ── Relay section (compiled only when ENABLE_RELAYS is defined) ────────── */
#ifdef ENABLE_RELAYS

/* Relays: RS1=PG10, RS2=PG11, RS3_1=PG12, RS3_2=PG13, RS4_1=PG14, RS4_2=PG15 */
static const struct gpio_dt_spec relays[] = {
    GPIO_DT_SPEC_GET(DT_ALIAS(relay0), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(relay1), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(relay2), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(relay3), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(relay4), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(relay5), gpios),
};

#define RELAY_STACK 512
K_THREAD_STACK_DEFINE(relay_stack, RELAY_STACK);
static struct k_thread relay_tid;

static void relay_thread(void *p1, void *p2, void *p3)
{
    bool on = false;

    while (1) {
        on = !on;
        for (int i = 0; i < ARRAY_SIZE(relays); i++) {
            gpio_pin_set_dt(&relays[i], on ? 1 : 0);
        }
        k_msleep(1000);
    }
}

#endif /* ENABLE_RELAYS */
/* ─────────────────────────────────────────────────────────────────────────── */

int main(void)
{
    /* Initialise green LEDs */
    for (int i = 0; i < ARRAY_SIZE(leds); i++) {
        gpio_pin_configure_dt(&leds[i], GPIO_OUTPUT_INACTIVE);
    }

    /* Initialise RGB channels */
    for (int i = 0; i < ARRAY_SIZE(rgb); i++) {
        gpio_pin_configure_dt(&rgb[i], GPIO_OUTPUT_INACTIVE);
    }

#ifdef ENABLE_RELAYS
    /* Initialise relays (start de-energised) */
    for (int i = 0; i < ARRAY_SIZE(relays); i++) {
        gpio_pin_configure_dt(&relays[i], GPIO_OUTPUT_INACTIVE);
    }

    /* Launch relay toggle thread (1 s period) */
    k_thread_create(&relay_tid, relay_stack, K_THREAD_STACK_SIZEOF(relay_stack),
                    relay_thread, NULL, NULL, NULL,
                    5, 0, K_NO_WAIT);
#endif /* ENABLE_RELAYS */

    /* Launch RGB cycling thread */
    k_thread_create(&rgb_tid, rgb_stack, K_THREAD_STACK_SIZEOF(rgb_stack),
                    rgb_thread, NULL, NULL, NULL,
                    5, 0, K_NO_WAIT);

    /* Main thread: sequential green LED chase at 200 ms per step */
    while (1) {
        for (int i = 0; i < ARRAY_SIZE(leds); i++) {
            gpio_pin_set_dt(&leds[i], 1);
            k_msleep(200);
            gpio_pin_set_dt(&leds[i], 0);
        }
    }

    return 0;
}
