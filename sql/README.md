# SQL Анализ данных Airbnb

[![SQL](https://img.shields.io/badge/SQL-Expert-blue)](https://sql-academy.org)

Аналитические SQL-запросы для учебной базы данных Airbnb. Запросы тестировались на платформе [sql-academy.org](https://sql-academy.org/ru/sandbox).

## Схема базы данных
![ERD Airbnb](https://sql-academy.org/static/images/schema_ru.png)

---

## Задание 1: Активные пользователи
**Задача:** Вернуть пользователей с >1 бронированием, с указанием первой/последней даты бронирования и общей стоимости.

```sql
SELECT u.id AS user_id,
    u.name,
    COUNT(r.id) AS booking_count,
    MIN(r.start_date) AS first_booking_date,
    MAX(r.start_date) AS last_booking_date,
    SUM(r.price) AS total_booking_cost
FROM Users u
    JOIN Reservations r ON u.id = r.user_id
GROUP BY u.id,
    u.name
HAVING COUNT(r.id) > 1
ORDER BY booking_count DESC,
    total_booking_cost DESC;
```

**Особенности решения:**
- Использование `JOIN` для связи пользователей и бронирований
- Фильтрация групп с помощью `HAVING`
- Сортировка по нескольким столбцам

---

## Задание 2: Годовая выручка (накопительный итог)
**Задача:** Рассчитать годовую выручку с накопительным итогом.

**Вариант с CTE и подзапросом:**
```sql
WITH yearly_totals AS (...)
SELECT ...;
```

**Вариант с оконной функцией (более оптимальный):**
```sql
SELECT EXTRACT(YEAR FROM r.start_date) AS booking_year,
    SUM(r.price) AS year_total,
    SUM(SUM(r.price)) OVER (ORDER BY EXTRACT(YEAR FROM r.start_date)) AS cumulative_total
FROM Reservations r
GROUP BY EXTRACT(YEAR FROM r.start_date)
ORDER BY booking_year;
```

**Сравнение подходов:** Оконные функции обеспечивают лучшую производительность на больших данных.

---

## Задание 3: Жильё с низким рейтингом
**Задача:** Найти жильё со средним рейтингом <= 2

```sql
SELECT rm.id AS room_id,
    rm.home_type,
    rm.address,
    rm.price,
    AVG(rv.rating) AS average_rating
FROM Rooms rm
    JOIN Reservations r ON rm.id = r.room_id
    JOIN Reviews rv ON r.id = rv.reservation_id
GROUP BY rm.id,
    rm.home_type,
    rm.address,
    rm.price
HAVING AVG(rv.rating) <= 2
```

**Особенности:** 
- Множественные `JOIN` для связи таблиц
- Использование `HAVING` для фильтрации по агрегатной функции

---

## Задание 4: Распределение рейтингов
**Задача:** Рассчитать процентное распределение оценок

```sql
WITH rating_counts AS (...),
total AS (...)
SELECT ...;
```

---

## Задание 5: Средняя длительность пребывания
**Задача:** Рассчитать среднюю длительность пребывания по жилью

```sql
SELECT rm.id AS room_id,
    rm.home_type,
    rm.address,
    ROUND(COALESCE(AVG(DATEDIFF(r.end_date, r.start_date)), 0), 0) AS avg_duration
FROM Rooms rm
    LEFT JOIN Reservations r ON rm.id = r.room_id
GROUP BY rm.id, rm.home_type, rm.address
ORDER BY avg_duration DESC;
```

**Особенности:**
- Использование `LEFT JOIN` для включения жилья без бронирований
- Обработка NULL через `COALESCE`
- Расчет длительности с помощью `DATEDIFF`

---

## Валидация запросов
Все запросы были протестированы на платформе sql-academy.org:
![Пример выполнения](screenshot.png)

> **Примечание:** Так как доступ к учебной БД ограничен платформой, результаты запросов не могут быть воспроизведены локально.
