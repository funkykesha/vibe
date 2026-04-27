#!/usr/bin/env node
'use strict';

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const { createElizaClient } = require('../lib/eliza-client');

const token = process.env.ELIZA_TOKEN;
if (!token) {
  console.error('ELIZA_TOKEN не задан');
  process.exit(1);
}

const eliza = createElizaClient({ token });

eliza.getModels().then(({ models, onValidated }) => {
  console.log(`Получено моделей: ${models.length}`);
  onValidated((validated) => {
    console.log(`Проверено: ${validated.length} доступно`);
    console.log(JSON.stringify(validated, null, 2));
    process.exit(0);
  });
}).catch((err) => {
  console.error('Ошибка:', err.message);
  process.exit(1);
});
