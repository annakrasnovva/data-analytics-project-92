--4 ШАГ
select count(customer_id) --считаем кол-во покупателей по уникальным id
from customers;


-- 5 ШАГ
-- 1 отчет top_10_total_income
select
    --склеиваем имя и фамилию продавца
    concat(e.first_name || ' ' || e.last_name) as seller,
    count(s.sales_id) as operations, --считаем операции
    floor(sum(p.price * s.quantity)) as income --считаем выручку
from sales as s
left join employees as e
    --джойним эту таблицу для имен продавцов
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id --а эту для цен товаров
group by 1
order by 3 desc --сортируем по выручке по убыванию
limit 10; --показываем только первые 10

-- 2 отчет lowest_average_income
with sales2 as (
    select
        --склеиваем имя и фамилию продавцов
        concat(e.first_name, ' ', e.last_name) as seller,
        --считаем среднюю выручку за сделку каждого продавца
        floor(avg(p.price * s.quantity)) as average_income
    from sales as s
    left join employees as e
        --из этой таблицы берем имена и фамилии продавцов
        on s.sales_person_id = e.employee_id
    left join products as p
        on s.product_id = p.product_id --из этой цены на товары
    group by 1 --группировка по продавцам
)

select *
from sales2
--сортируем по ср. выручке за сделку меньше чем ср. выручка по всем продавцам
where average_income < (select avg(average_income) from sales2)
order by 2; --сортируем по ср. выручке по возрастанию

-- 3 отчет day_of_the_week_income
with sales3 as (
    select
        --склеиваем имя и фамилию продавцов
        concat(e.first_name || ' ' || e.last_name) as seller,
        --из даты берем название дня недели
        to_char(s.sale_date, 'day') as day_of_week,
        floor(sum(p.price * s.quantity)) as income, --считаем выручку
        extract(dow from s.sale_date) + 1 as num_week
    --из даты берем порядковый номер дня недели для сортировки и прибавляем
    --единицу, для того чтобы неделя начиналась с понедельника
    from sales as s
    left join employees as e
        --джойним эту таблицу для имен продавцов
        on s.sales_person_id = e.employee_id
    left join products as p
        on s.product_id = p.product_id  --а из этой берем цены товаров
    group by 1, 2, 4
    order by 4, 1 --сортируем по порядковому номеру дня недели и продавцу
)

select
    seller,
    day_of_week,
    income --используем CTE для того, чтобы отсортировать таблицу
    --по порядковому номеру дня недели, но не отображать этот столбец
from sales3;

-- 6 ШАГ
-- 1 отчет age_groups
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        when age >= 41 then '40+'
    end as age_category, -- создаем колонку с категориями возрастов
    count(age) as age_count  -- считаем кол-во клиентов по возрастным категориям
from customers
group by 1
order by 1;

-- 2 отчет customers_by_month
select
    --убираем из даты день, оставляя год и месяц
    to_char(s.sale_date, 'yyyy-mm') as selling_month,
    --считаем уникальных покупателей
    count(distinct s.customer_id) as total_customers,
    sum(p.price * s.quantity) as income --считаем выручку за месяц
from sales as s
left join products as p
    -- соединяем таблицу products для значения price из него
    on s.product_id = p.product_id
group by 1
order by 1; -- сортируем по дате

-- 3 отчет special_offer
with sp_of as (
    select
        c.customer_id,
        --берем id покупателя для последующей фильтрации
        s.sale_date, --дата покупки
        p.price, --берем цену, будем использовать для фильтрации
        concat(c.first_name || ' ' || c.last_name) as customer,
        --склеиваем имя и фамилию клиентов
        concat(e.first_name || ' ' || e.last_name) as seller,
        --склеиваем имя и фамилию продавцов
        row_number() over (partition by c.customer_id order by s.sale_date)
        as rn
        --нумеруем покупки покупателей по дате
    from sales as s
    left join customers as c --джойним эту таблицу для имен клиентов
        on s.customer_id = c.customer_id
    left join employees as e
        --джойним эту таблицу для имен продавцов
        on s.sales_person_id = e.employee_id
    left join products as p  --джойним эту таблицу для цен
        on s.product_id = p.product_id
    order by customers.customer_id asc --сортируем по id покупателей
)

--выводим имена покупателей, дату покупки и имя продавца
select
    sp_of.customer,
    sp_of.sale_date,
    sp_of.seller
from sp_of
where sp_of.rn = 1 and sp_of.price = 0;
--сортируем по первой покупке И цене = 0(акция)
