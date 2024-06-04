--4 ШАГ
select count(customer_id) --считаем кол-во покупателей по уникальным id
from customers c
;


--5 ШАГ
-- 1 отчет
with sales1 as (
select concat(e.first_name, ' ', e.last_name) as seller, --склеиваем имя и фамилию работников
count(s.sales_id) as operations, --считаем операции
p.price * s.quantity as income -- считаем выручку
from sales s
left join employees e
  on s.sales_person_id = e.employee_id
left join products p
  on s.product_id = p.product_id 
group by 1, 3
)

select seller,
sum(operations) as operations, --суммируем операции по каждому работнику
floor(sum(income)) as income -- суммируем выручку по каждому работнику
from sales1 
group by 1
order by 3 desc --сортируем выручку по убыванию
limit 10 -- сортируем лимит строк
;

-- 2 отчет
with sales2 as (
with saless as (
select concat(e.first_name, ' ', e.last_name) as seller,
count(s.sales_id) as operations, 
p.price * s.quantity as income
from sales s
left join employees e
  on s.sales_person_id = e.employee_id
left join products p
  on s.product_id = p.product_id 
group by 1, 3
)

select seller,
sum(operations) as operations,
sum(income) as income -- суммируем и округляем выручку по каждому работнику
from saless ss 
group by 1
)

select seller,
floor(income/operations) as average_income -- считаем среднюю выручку за 1 операцию для каждого работника
from sales2
where floor(income/operations) < (select avg(floor(income/operations)) from sales2) --убираем выручки, которые >= средней выручке по всем работникам
order by 2
;

-- 3 отчет
with sales3 as (
select concat(e.first_name, ' ', e.last_name) as seller,
floor(sum(p.price * s.quantity)) as income,
extract(dow from s.sale_date) + 1 as num_week -- переводим дату в номер дня недели, +1 для того, что бы неделя начиналась с понедельника, а не воскресенья
from sales s
left join employees e
  on s.sales_person_id = e.employee_id
left join products p
  on s.product_id = p.product_id
group by 1, 3
order by 3, 1
)

select seller,
case
	when num_week = 1 then 'monday'
	when num_week = 2 then 'tuesday'
	when num_week = 3 then 'wednesday'
	when num_week = 4 then 'thursday'
	when num_week = 5 then 'friday'
	when num_week = 6 then 'saturday'
	when num_week = 7 then 'sunday'
end as day_of_week, -- переводим все номера дней недель в их названия
income
from sales3
;
