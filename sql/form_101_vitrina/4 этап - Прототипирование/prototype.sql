-- прототип аналитической витрины формы 101 за май 2021 года


-- у счетов 61209 и 61212 в поле kind_account стоял символ '-' вместо 'А'  
update bank.account_dbt
set kind_account = 'А'
where balance in ('61209', '61212')
  and code_currency = 0
  and kind_account = '-';

with
-- справочник счетов, актуальных на май 2021
al as (
  select distinct
    case
      when b.chapter = 1 then 'А'
      when b.chapter = 2 then 'Б'
      when b.chapter = 3 then 'В'
      when b.chapter = 4 then 'Г'
    end as plan,
    a.balance,
    case
      when a.kind_account = 'А' then '1'
      when a.kind_account = 'П' then '2'
    end as a_p,
    a.kind_account
  from bank.account_dbt a
  join bank.balance_dbt b on a.balance = b.balance and b.chapter in (1, 2, 3, 4)
  where a.open_date <= '2021-05-31 23:59:59'::timestamp
    and (a.close_date is null or a.close_date > '2021-05-01 00:00:00'::timestamp)
    and a.kind_account in ('А', 'П')
    and a.code_currency = 0
),

-- ВХОДЯЩИЕ ОСТАТКИ на 01.05.2021

-- итого (столбец 4) – все счета с code_currency = 0
cover_rest as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and open_date <= '2021-04-30 23:59:59'::timestamp
    and (close_date is null or close_date > '2021-04-30 00:00:00'::timestamp)
),
last_rest as (
  select cr.balance, cr.kind_account, r.rest
  from cover_rest cr
  join bank.restdate_dbt r on cr.account = r.account and cr.chapter = r.chapter and cr.code_currency = r.code_currency
  where r.date_carry = (
    select max(r2.date_carry)
    from bank.restdate_dbt r2
    where r2.account = cr.account
      and r2.chapter = cr.chapter
      and r2.code_currency = cr.code_currency
      and r2.date_carry <= '2021-04-30 23:59:59'::timestamp
  )
),
v as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(case when kind_account = 'А' then -rest else rest end) as vitg
  from last_rest
  group by num_sc
),

-- в рублях (столбец 2) – рублёвые счета без type_account
cover_rest_rub as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and substring(account, 6, 3) = '810'
    and open_date <= '2021-04-30 23:59:59'::timestamp
    and (close_date is null or close_date > '2021-04-30 00:00:00'::timestamp)
),
last_rest_rub as (
  select cr.balance, cr.kind_account, r.rest
  from cover_rest_rub cr
  join bank.restdate_dbt r on cr.account = r.account and cr.chapter = r.chapter and cr.code_currency = r.code_currency
  where r.date_carry = (
    select max(r2.date_carry)
    from bank.restdate_dbt r2
    where r2.account = cr.account
      and r2.chapter = cr.chapter
      and r2.code_currency = cr.code_currency
      and r2.date_carry <= '2021-04-30 23:59:59'::timestamp
  )
),
v_rub as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(case when kind_account = 'А' then -rest else rest end) as vitg_rub
  from last_rest_rub
  group by num_sc
),

-- инвалюта (столбец 3) – счета покрытия для иностранной валюты
cover_rest_currency as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and type_account LIKE 'П%'                   
    and substring(account, 6, 3) <> '810'    
    and open_date <= '2021-04-30 23:59:59'::timestamp
    and (close_date is null or close_date > '2021-04-30 00:00:00'::timestamp)
),
last_rest_currency as (
  select cr.balance, cr.kind_account, r.rest
  from cover_rest_currency cr
  join bank.restdate_dbt r on cr.account = r.account and cr.chapter = r.chapter and cr.code_currency = r.code_currency
  where r.date_carry = (
    select max(r2.date_carry)
    from bank.restdate_dbt r2
    where r2.account = cr.account
      and r2.chapter = cr.chapter
      and r2.code_currency = cr.code_currency
      and r2.date_carry <= '2021-04-30 23:59:59'::timestamp
  )
),
v_currency as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(case when kind_account = 'А' then -rest else rest end) as vitg_currency
  from last_rest_currency
  group by num_sc
),

-- ИСХОДЯЩИЕ ОСТАТКИ на 31.05.2021

-- итого (столбец 13) – все счета с code_currency = 0
cover_rest_out as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and open_date <= '2021-05-31 23:59:59'::timestamp
    and (close_date is null or close_date > '2021-05-31 00:00:00'::timestamp)
),
last_rest_out as (
  select cr.balance, cr.kind_account, r.rest
  from cover_rest_out cr
  join bank.restdate_dbt r on cr.account = r.account and cr.chapter = r.chapter and cr.code_currency = r.code_currency
  where r.date_carry = (
    select max(r2.date_carry)
    from bank.restdate_dbt r2
    where r2.account = cr.account
      and r2.chapter = cr.chapter
      and r2.code_currency = cr.code_currency
      and r2.date_carry <= '2021-05-31 23:59:59'::timestamp
  )
),
v_out_total as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(case when kind_account = 'А' then -rest else rest end) as iitg_total
  from last_rest_out
  group by num_sc
),

-- в рублях (столбец 11) – рублёвые счета
cover_rest_out_rub as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and substring(account, 6, 3) = '810'
    and open_date <= '2021-05-31 23:59:59'::timestamp
    and (close_date is null or close_date > '2021-05-31 00:00:00'::timestamp)
),
last_rest_out_rub as (
  select cr.balance, cr.kind_account, r.rest
  from cover_rest_out_rub cr
  join bank.restdate_dbt r on cr.account = r.account and cr.chapter = r.chapter and cr.code_currency = r.code_currency
  where r.date_carry = (
    select max(r2.date_carry)
    from bank.restdate_dbt r2
    where r2.account = cr.account
      and r2.chapter = cr.chapter
      and r2.code_currency = cr.code_currency
      and r2.date_carry <= '2021-05-31 23:59:59'::timestamp
  )
),
v_out_rub as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(case when kind_account = 'А' then -rest else rest end) as iitg_rub
  from last_rest_out_rub
  group by num_sc
),

-- инвалюта (столбец 12) – счета покрытия для иностранной валюты
cover_rest_out_currency as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and type_account LIKE 'П%'               
    and substring(account, 6, 3) <> '810'
    and open_date <= '2021-05-31 23:59:59'::timestamp
    and (close_date is null or close_date > '2021-05-31 00:00:00'::timestamp)
),
last_rest_out_currency as (
  select cr.balance, cr.kind_account, r.rest
  from cover_rest_out_currency cr
  join bank.restdate_dbt r on cr.account = r.account and cr.chapter = r.chapter and cr.code_currency = r.code_currency
  where r.date_carry = (
    select max(r2.date_carry)
    from bank.restdate_dbt r2
    where r2.account = cr.account
      and r2.chapter = cr.chapter
      and r2.code_currency = cr.code_currency
      and r2.date_carry <= '2021-05-31 23:59:59'::timestamp
  )
),
v_out_currency as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(case when kind_account = 'А' then -rest else rest end) as iitg_currency
  from last_rest_out_currency
  group by num_sc
),

-- ОБОРОТЫ ЗА МАЙ 2021

-- итого (столбцы 7 и 10) – все счета с code_currency = 0
cover_may as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and open_date <= '2021-05-31 23:59:59'::timestamp
    and (close_date is null or close_date >= '2021-05-01 00:00:00'::timestamp)
),

-- обороты по дебету итого (столбец 7)
oa_det as (
  select cm.balance, sum(ar.sum) as oitga
  from cover_may cm
  join bank.arhdoc_dbt ar on cm.account = ar.real_payer and cm.chapter = ar.chapter and cm.code_currency = ar.code_currency
  where ar.date_carry >= '2021-05-01 00:00:00'::timestamp
    and ar.date_carry < '2021-06-01 00:00:00'::timestamp
  group by cm.balance
),
oa as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(oitga) as oitga
  from oa_det
  group by num_sc
),

-- обороты по кредиту итого (столбец 10)
op_det as (
  select cm.balance, sum(ar.sum) as oitgp
  from cover_may cm
  join bank.arhdoc_dbt ar on cm.account = ar.real_receiver and cm.chapter = ar.chapter and cm.code_currency = ar.code_currency
  where ar.date_carry >= '2021-05-01 00:00:00'::timestamp
    and ar.date_carry < '2021-06-01 00:00:00'::timestamp
  group by cm.balance
),
op as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(oitgp) as oitgp
  from op_det
  group by num_sc
),

-- рублёвые обороты (код 810)

-- дебет рубли (столбец 5)
cover_may_rub as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and substring(account, 6, 3) = '810'
    and open_date <= '2021-05-31 23:59:59'::timestamp
    and (close_date is null or close_date >= '2021-05-01 00:00:00'::timestamp)
),
oa_rub_det as (
  select cm.balance, sum(ar.sum) as oitga_rub
  from cover_may_rub cm
  join bank.arhdoc_dbt ar on cm.account = ar.real_payer and cm.chapter = ar.chapter and cm.code_currency = ar.code_currency
  where ar.date_carry >= '2021-05-01 00:00:00'::timestamp
    and ar.date_carry < '2021-06-01 00:00:00'::timestamp
  group by cm.balance
),
oa_rub as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(oitga_rub) as oitga_rub
  from oa_rub_det
  group by num_sc
),

-- кредит рубли (столбец 8)
op_rub_det as (
  select cm.balance, sum(ar.sum) as oitgp_rub
  from cover_may_rub cm
  join bank.arhdoc_dbt ar on cm.account = ar.real_receiver and cm.chapter = ar.chapter and cm.code_currency = ar.code_currency
  where ar.date_carry >= '2021-05-01 00:00:00'::timestamp
    and ar.date_carry < '2021-06-01 00:00:00'::timestamp
  group by cm.balance
),
op_rub as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(oitgp_rub) as oitgp_rub
  from op_rub_det
  group by num_sc
),

-- валютные обороты (код ≠ 810, счета покрытия)

-- дебет валюта (столбец 6)
cover_may_currency as (
  select account, balance, kind_account, chapter, code_currency
  from bank.account_dbt
  where code_currency = 0
    and type_account LIKE 'П%'               
    and substring(account, 6, 3) <> '810'
    and open_date <= '2021-05-31 23:59:59'::timestamp
    and (close_date is null or close_date >= '2021-05-01 00:00:00'::timestamp)
),
oa_currency_det as (
  select cm.balance, sum(ar.sum) as oitga_currency
  from cover_may_currency cm
  join bank.arhdoc_dbt ar on cm.account = ar.real_payer and cm.chapter = ar.chapter and cm.code_currency = ar.code_currency
  where ar.date_carry >= '2021-05-01 00:00:00'::timestamp
    and ar.date_carry < '2021-06-01 00:00:00'::timestamp
  group by cm.balance
),
oa_currency as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(oitga_currency) as oitga_currency
  from oa_currency_det
  group by num_sc
),

-- кредит валюта (столбец 9)
op_currency_det as (
  select cm.balance, sum(ar.sum) as oitgp_currency
  from cover_may_currency cm
  join bank.arhdoc_dbt ar on cm.account = ar.real_receiver and cm.chapter = ar.chapter and cm.code_currency = ar.code_currency
  where ar.date_carry >= '2021-05-01 00:00:00'::timestamp
    and ar.date_carry < '2021-06-01 00:00:00'::timestamp
  group by cm.balance
),
op_currency as (
  select
    case
      when balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when balance in ('40701','40702','40703') then '407'
      when balance in ('40802','40825') then '408.1'
      when balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else balance::varchar(5)
    end as num_sc,
    sum(oitgp_currency) as oitgp_currency
  from op_currency_det
  group by num_sc
),

-- перечень всех агрегированных номеров счетов
sub as (
  select
    al.plan,
    case
      when al.balance in ('30413','30416','30417','30418','30419','30424','30425','30427') then '304.1'
      when al.balance in ('40701','40702','40703') then '407'
      when al.balance in ('40802','40825') then '408.1'
      when al.balance in ('47402','47404','47406','47408','47410','47413','47415') then '474.1'
      else al.balance::varchar(5)
    end as num_sc,
    al.a_p
  from al
  group by plan, num_sc, a_p
)

-- ВИТРИНА
select
  sub.plan as "Раздел",
  sub.num_sc as "Номер счета",
  sub.a_p as "А/П",

  -- входящие остатки
  round(coalesce(v_rub.vitg_rub, 0) / 1000)::integer as "Входящие остатки – в рублях",
  round(coalesce(v_currency.vitg_currency, 0) / 1000)::integer as "Входящие остатки – ин. валюта",
  round(coalesce(v.vitg, 0) / 1000)::integer as "Входящие остатки – итого",

  -- обороты по дебету
  round(coalesce(oa_rub.oitga_rub, 0) / 1000)::integer as "Обороты по дебету – в рублях",
  round(coalesce(oa_currency.oitga_currency, 0) / 1000)::integer as "Обороты по дебету – ин. валюта",
  round(coalesce(oa.oitga, 0) / 1000)::integer as "Обороты по дебету – итого",

  -- обороты по кредиту
  round(coalesce(op_rub.oitgp_rub, 0) / 1000)::integer as "Обороты по кредиту – в рублях",
  round(coalesce(op_currency.oitgp_currency, 0) / 1000)::integer as "Обороты по кредиту – ин. валюта",
  round(coalesce(op.oitgp, 0) / 1000)::integer as "Обороты по кредиту – итого",

  -- исходящие остатки
  round(coalesce(v_out_rub.iitg_rub, 0) / 1000)::integer as "Исходящие остатки – в рублях",
  round(coalesce(v_out_currency.iitg_currency, 0) / 1000)::integer as "Исходящие остатки – ин. валюта",
  round(coalesce(v_out_total.iitg_total, 0) / 1000)::integer as "Исходящие остатки – итого",

  '2021-06-01'::date as "Дата"
from sub
left join v on sub.num_sc = v.num_sc
left join v_rub on sub.num_sc = v_rub.num_sc
left join v_currency on sub.num_sc = v_currency.num_sc
left join v_out_total on sub.num_sc = v_out_total.num_sc
left join v_out_rub on sub.num_sc = v_out_rub.num_sc
left join v_out_currency on sub.num_sc = v_out_currency.num_sc
left join oa on sub.num_sc = oa.num_sc
left join oa_rub on sub.num_sc = oa_rub.num_sc
left join oa_currency on sub.num_sc = oa_currency.num_sc
left join op on sub.num_sc = op.num_sc
left join op_rub on sub.num_sc = op_rub.num_sc
left join op_currency on sub.num_sc = op_currency.num_sc
where sub.num_sc in ('30126','30601','42601','90701','91203','91207','91507','407','408.1','474.1', '61209','61212')
   or coalesce(v.vitg, 0) <> 0
   or coalesce(oa.oitga, 0) <> 0
   or coalesce(op.oitgp, 0) <> 0
   or coalesce(v_out_total.iitg_total, 0) <> 0
order by sub.plan, sub.a_p, sub.num_sc;


