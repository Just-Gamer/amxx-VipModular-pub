# Modular Vip System

Модульная система привилегий.

## Инструкции по настройке

- [Основные настройки](readme/configs.md)
- [Контроллер предметов](readme/items.md)
- [Стандартные расширения](readme/default-extensions.md)
- [Сторонние расширения](readme/thirdparty-extensions.md)

## Серверные команды

|Команда                            |Описание
|:---                               |:---
|`vipm_update_users`                |Обновляет привилегии у всех игроков
|`vipm_info`                        |Выводит информацию о системе привилегий
||
|`vipm_modules`                     |Выводит таблицу модулей и их статусов
|`vipm_module_params <ModuleName>`  |Выводит таблицу параметров указанного модуля
||
|`vipm_limits`                      |Выводит таблицу типов проверок и некоторую информацию о них
|`vipm_limit_params <LimitType>`    |Выводит таблицу параметров указанного типа проверки
||
|`vipm_ic_types`                    |Выводит таблицу типов предметов

## Идеи

- _\[Items\]_ Добавить предмет(ы) типа "Здоровье" и "Броня".
  - Только хз зачем тогда будет нужен `SpawnHealth`)
- _\[Modules\]_ Добавить модуль защиты.
- _\[Extensions\]_ Вынести расширения GameCMS в отдельные репозитории.
- _\[Configs\]_ Добавить глобальные настройки типа ключ-значение, на которые можно ссылаться из основных конфигов как на файлы, только с префиксом Var:
- _\[Modules\]_ Переработать обьедининение параметров модулей
- _\[ReadMe\]_ Нарисовать схему взаимодействия компонентов системы
- _\[IC\]_ Придумать как норм отвязать IC от ядра и, возможно, вынести его в отдельный репо
