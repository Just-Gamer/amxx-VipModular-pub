# Command

Выполнение команды от имени игрока или сервера.

## Пример

```jsonc
{
    "Type": "Command",

    "Command": "HealthNade_Give {UserId}",
    "ByServer": true
}
```

## Параметры

- `Command`
  - Серверная или клиентская команда.
  - Возможна подстановка значений. Доступные значения:
    - `{UserId}` - индекс игрока, которому выдаётся этот предмет.
- `ByServer`
  - Если равно `true`, команда будет выполнена как серверная, иначе как клиентская.
