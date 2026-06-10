with swap as (
  select r0.account, r0.date_carry, r0.rest as rest0, rv.rest as restv, rv.code_currency
  from bank.restdate_dbt r0
  join bank.restdate_dbt rv
    on r0.account = rv.account and r0.date_carry = rv.date_carry
  where r0.code_currency = 0
    and rv.code_currency in (840, 978)
    and r0.date_carry between '2021-05-01' and '2021-05-31'
    and r0.account like '20202%'
    and abs(r0.rest) < abs(rv.rest)
)
update bank.restdate_dbt r
set rest = case
  when r.code_currency = 0 then sw.restv
  when r.code_currency = sw.code_currency then sw.rest0
end
from swap sw
where r.account = sw.account
  and r.date_carry = sw.date_carry
  and r.code_currency in (0, sw.code_currency);
