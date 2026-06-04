# Как интегрировать платёжные системы вроде Stripe

> Этап 2 · Бэкенд

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-2/backend/stripe-payment.md) · [Полный перевод](../../../lesson-originals-ru/stage-2/backend/stripe-payment.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/stripe-payment/index.md)

Урок про всю цепочку оплаты на примере Stripe: цену задаёт бэкенд, права активирует Webhook, статус хранится в собственной БД.

- Поток: фронтенд → бэкенд создаёт Checkout Session → Stripe → Webhook → БД.
- Страница `success` — не подтверждение; доверять только Webhook и проверять его подпись.
- Частые ошибки: сумма с фронтенда, нет сырого body, нет идемпотентности.
- Выбор провайдера по региону: Stripe, Alipay/WeChat, MoR (Paddle, Lemon Squeezy).
