# Как интегрировать платёжные системы вроде Stripe

> Этап 2 · Бэкенд

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-2/backend/stripe-payment.md) · **Расширенно** · [Полный перевод](../../../lesson-originals-ru/stage-2/backend/stripe-payment.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-2/backend/stripe-payment/index.md)


## О чём урок
Урок объясняет, как добавить приём платежей в продукт на примере Stripe. Главный акцент — не на кнопке оплаты, а на всей цепочке: кто определяет цену, кто подтверждает успешный платёж, кто обновляет базу данных. Показан минимально жизнеспособный платёжный поток и промпты, позволяющие делегировать интеграцию AI.

## Ключевые темы
- Три главных принципа: цену определяет бэкенд (не фронтенд); права активирует Webhook (не страница `success`); статус оплаты обязательно хранится в собственной БД.
- Почему нельзя подключать Stripe напрямую из фронтенда (подмена цены, утечка ключей, ненадёжное подтверждение оплаты).
- Минимальный платёжный поток: пользователь → фронтенд → бэкенд создаёт Checkout Session → Stripe → Webhook → обновление БД.
- 5 шагов быстрого старта: создание Product и Price в Stripe (получение `price_id`), переменные окружения, создание Checkout Session на бэкенде, переход на оплату с фронтенда, обработка Webhook.
- Приложение: ключевые объекты Stripe (Product, Price, Checkout Session, Subscription, Customer, Webhook), события подписок (`checkout.session.completed`, `invoice.paid`, `invoice.payment_failed`, `customer.subscription.deleted`).
- Выбор платёжного решения по регионам: Stripe, PayPal, Paddle, Lemon Squeezy (MoR), Airwallex, Adyen, Alipay/WeChat Pay.

## Главные выводы
- Страница `success` означает лишь «браузер выполнил переход», а Webhook — официальное подтверждение оплаты от Stripe; система должна доверять только Webhook.
- Подпись Webhook нужно проверять, чтобы исключить поддельные уведомления.
- Четыре частые ошибки: считать `success` подтверждением оплаты; передавать сумму с фронтенда; дать `express.json()` обработать тело до проверки подписи (нужен сырой body); отсутствие идемпотентности при повторах Webhook.
- Выбор провайдера зависит от региона: Stripe — для зарубежных SaaS, Alipay/WeChat — для материкового Китая, MoR-решения (Paddle, Lemon Squeezy) — чтобы не заниматься налогами самостоятельно.

## Инструменты и технологии
- Stripe (Checkout, Webhooks, Subscriptions, Stripe CLI: `stripe login`, `stripe listen`)
- Supabase (хранение статуса оплаты, service_role-ключ)
- AI-инструменты (Codex, Claude Code, Trae, Cursor) для интеграции по промптам
- Альтернативы: PayPal, Paddle, Lemon Squeezy, Airwallex, Adyen, Alipay, WeChat Pay
