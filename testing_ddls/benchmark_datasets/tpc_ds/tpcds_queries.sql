-- ============================================
-- TPC-DS Query 1
-- ============================================
-- start query 1 in stream 0 using template query1.tpl 
WITH customer_total_return 
     AS (SELECT sr_customer_sk     AS ctr_customer_sk, 
                sr_store_sk        AS ctr_store_sk, 
                Sum(sr_return_amt) AS ctr_total_return 
         FROM   store_returns, 
                date_dim 
         WHERE  sr_returned_date_sk = d_date_sk 
                AND d_year = 2001 
         GROUP  BY sr_customer_sk, 
                   sr_store_sk) 
SELECT c_customer_id 
FROM   customer_total_return ctr1, 
       store, 
       customer 
WHERE  ctr1.ctr_total_return > (SELECT Avg(ctr_total_return) * 1.2 
                                FROM   customer_total_return ctr2 
                                WHERE  ctr1.ctr_store_sk = ctr2.ctr_store_sk) 
       AND s_store_sk = ctr1.ctr_store_sk 
       AND s_state = 'TN' 
       AND ctr1.ctr_customer_sk = c_customer_sk 
ORDER  BY c_customer_id
LIMIT 100;

-- ============================================
-- TPC-DS Query 2
-- ============================================
-- start query 2 in stream 0 using template query2.tpl  
WITH wscs 
     AS (SELECT sold_date_sk, 
                sales_price 
         FROM   (SELECT ws_sold_date_sk    sold_date_sk, 
                        ws_ext_sales_price sales_price 
                 FROM   web_sales) 
         UNION ALL 
         (SELECT cs_sold_date_sk    sold_date_sk, 
                 cs_ext_sales_price sales_price 
          FROM   catalog_sales)), 
     wswscs 
     AS (SELECT d_week_seq, 
                Sum(CASE 
                      WHEN ( d_day_name = 'Sunday' ) THEN sales_price 
                      ELSE NULL 
                    END) sun_sales, 
                Sum(CASE 
                      WHEN ( d_day_name = 'Monday' ) THEN sales_price 
                      ELSE NULL 
                    END) mon_sales, 
                Sum(CASE 
                      WHEN ( d_day_name = 'Tuesday' ) THEN sales_price 
                      ELSE NULL 
                    END) tue_sales, 
                Sum(CASE 
                      WHEN ( d_day_name = 'Wednesday' ) THEN sales_price 
                      ELSE NULL 
                    END) wed_sales, 
                Sum(CASE 
                      WHEN ( d_day_name = 'Thursday' ) THEN sales_price 
                      ELSE NULL 
                    END) thu_sales, 
                Sum(CASE 
                      WHEN ( d_day_name = 'Friday' ) THEN sales_price 
                      ELSE NULL 
                    END) fri_sales, 
                Sum(CASE 
                      WHEN ( d_day_name = 'Saturday' ) THEN sales_price 
                      ELSE NULL 
                    END) sat_sales 
         FROM   wscs, 
                date_dim 
         WHERE  d_date_sk = sold_date_sk 
         GROUP  BY d_week_seq) 
SELECT d_week_seq1, 
       Round(sun_sales1 / sun_sales2, 2), 
       Round(mon_sales1 / mon_sales2, 2), 
       Round(tue_sales1 / tue_sales2, 2), 
       Round(wed_sales1 / wed_sales2, 2), 
       Round(thu_sales1 / thu_sales2, 2), 
       Round(fri_sales1 / fri_sales2, 2), 
       Round(sat_sales1 / sat_sales2, 2) 
FROM   (SELECT wswscs.d_week_seq d_week_seq1, 
               sun_sales         sun_sales1, 
               mon_sales         mon_sales1, 
               tue_sales         tue_sales1, 
               wed_sales         wed_sales1, 
               thu_sales         thu_sales1, 
               fri_sales         fri_sales1, 
               sat_sales         sat_sales1 
        FROM   wswscs, 
               date_dim 
        WHERE  date_dim.d_week_seq = wswscs.d_week_seq 
               AND d_year = 1998) y, 
       (SELECT wswscs.d_week_seq d_week_seq2, 
               sun_sales         sun_sales2, 
               mon_sales         mon_sales2, 
               tue_sales         tue_sales2, 
               wed_sales         wed_sales2, 
               thu_sales         thu_sales2, 
               fri_sales         fri_sales2, 
               sat_sales         sat_sales2 
        FROM   wswscs, 
               date_dim 
        WHERE  date_dim.d_week_seq = wswscs.d_week_seq 
               AND d_year = 1998 + 1) z 
WHERE  d_week_seq1 = d_week_seq2 - 53 
ORDER  BY d_week_seq1;

-- ============================================
-- TPC-DS Query 3
-- ============================================
-- start query 3 in stream 0 using template query3.tpl 
SELECT dt.d_year, 
               item.i_brand_id          brand_id, 
               item.i_brand             brand, 
               Sum(ss_ext_discount_amt) sum_agg 
FROM   date_dim dt, 
       store_sales, 
       item 
WHERE  dt.d_date_sk = store_sales.ss_sold_date_sk 
       AND store_sales.ss_item_sk = item.i_item_sk 
       AND item.i_manufact_id = 427 
       AND dt.d_moy = 11 
GROUP  BY dt.d_year, 
          item.i_brand, 
          item.i_brand_id 
ORDER  BY dt.d_year, 
          sum_agg DESC, 
          brand_id
LIMIT 100;

-- ============================================
-- TPC-DS Query 4
-- ============================================
-- start query 4 in stream 0 using template query4.tpl 
WITH year_total 
     AS (SELECT c_customer_id                       customer_id, 
                c_first_name                        customer_first_name, 
                c_last_name                         customer_last_name, 
                c_preferred_cust_flag               customer_preferred_cust_flag 
                , 
                c_birth_country 
                customer_birth_country, 
                c_login                             customer_login, 
                c_email_address                     customer_email_address, 
                d_year                              dyear, 
                Sum(( ( ss_ext_list_price - ss_ext_wholesale_cost 
                        - ss_ext_discount_amt 
                      ) 
                      + 
                          ss_ext_sales_price ) / 2) year_total, 
                's'                                 sale_type 
         FROM   customer, 
                store_sales, 
                date_dim 
         WHERE  c_customer_sk = ss_customer_sk 
                AND ss_sold_date_sk = d_date_sk 
         GROUP  BY c_customer_id, 
                   c_first_name, 
                   c_last_name, 
                   c_preferred_cust_flag, 
                   c_birth_country, 
                   c_login, 
                   c_email_address, 
                   d_year 
         UNION ALL 
         SELECT c_customer_id                             customer_id, 
                c_first_name                              customer_first_name, 
                c_last_name                               customer_last_name, 
                c_preferred_cust_flag 
                customer_preferred_cust_flag, 
                c_birth_country                           customer_birth_country 
                , 
                c_login 
                customer_login, 
                c_email_address                           customer_email_address 
                , 
                d_year                                    dyear 
                , 
                Sum(( ( ( cs_ext_list_price 
                          - cs_ext_wholesale_cost 
                          - cs_ext_discount_amt 
                        ) + 
                              cs_ext_sales_price ) / 2 )) year_total, 
                'c'                                       sale_type 
         FROM   customer, 
                catalog_sales, 
                date_dim 
         WHERE  c_customer_sk = cs_bill_customer_sk 
                AND cs_sold_date_sk = d_date_sk 
         GROUP  BY c_customer_id, 
                   c_first_name, 
                   c_last_name, 
                   c_preferred_cust_flag, 
                   c_birth_country, 
                   c_login, 
                   c_email_address, 
                   d_year 
         UNION ALL 
         SELECT c_customer_id                             customer_id, 
                c_first_name                              customer_first_name, 
                c_last_name                               customer_last_name, 
                c_preferred_cust_flag 
                customer_preferred_cust_flag, 
                c_birth_country                           customer_birth_country 
                , 
                c_login 
                customer_login, 
                c_email_address                           customer_email_address 
                , 
                d_year                                    dyear 
                , 
                Sum(( ( ( ws_ext_list_price 
                          - ws_ext_wholesale_cost 
                          - ws_ext_discount_amt 
                        ) + 
                              ws_ext_sales_price ) / 2 )) year_total, 
                'w'                                       sale_type 
         FROM   customer, 
                web_sales, 
                date_dim 
         WHERE  c_customer_sk = ws_bill_customer_sk 
                AND ws_sold_date_sk = d_date_sk 
         GROUP  BY c_customer_id, 
                   c_first_name, 
                   c_last_name, 
                   c_preferred_cust_flag, 
                   c_birth_country, 
                   c_login, 
                   c_email_address, 
                   d_year) 
SELECT t_s_secyear.customer_id, 
               t_s_secyear.customer_first_name, 
               t_s_secyear.customer_last_name, 
               t_s_secyear.customer_preferred_cust_flag 
FROM   year_total t_s_firstyear, 
       year_total t_s_secyear, 
       year_total t_c_firstyear, 
       year_total t_c_secyear, 
       year_total t_w_firstyear, 
       year_total t_w_secyear 
WHERE  t_s_secyear.customer_id = t_s_firstyear.customer_id 
       AND t_s_firstyear.customer_id = t_c_secyear.customer_id 
       AND t_s_firstyear.customer_id = t_c_firstyear.customer_id 
       AND t_s_firstyear.customer_id = t_w_firstyear.customer_id 
       AND t_s_firstyear.customer_id = t_w_secyear.customer_id 
       AND t_s_firstyear.sale_type = 's' 
       AND t_c_firstyear.sale_type = 'c' 
       AND t_w_firstyear.sale_type = 'w' 
       AND t_s_secyear.sale_type = 's' 
       AND t_c_secyear.sale_type = 'c' 
       AND t_w_secyear.sale_type = 'w' 
       AND t_s_firstyear.dyear = 2001 
       AND t_s_secyear.dyear = 2001 + 1 
       AND t_c_firstyear.dyear = 2001 
       AND t_c_secyear.dyear = 2001 + 1 
       AND t_w_firstyear.dyear = 2001 
       AND t_w_secyear.dyear = 2001 + 1 
       AND t_s_firstyear.year_total > 0 
       AND t_c_firstyear.year_total > 0 
       AND t_w_firstyear.year_total > 0 
       AND CASE 
             WHEN t_c_firstyear.year_total > 0 THEN t_c_secyear.year_total / 
                                                    t_c_firstyear.year_total 
             ELSE NULL 
           END > CASE 
                   WHEN t_s_firstyear.year_total > 0 THEN 
                   t_s_secyear.year_total / 
                   t_s_firstyear.year_total 
                   ELSE NULL 
                 END 
       AND CASE 
             WHEN t_c_firstyear.year_total > 0 THEN t_c_secyear.year_total / 
                                                    t_c_firstyear.year_total 
             ELSE NULL 
           END > CASE 
                   WHEN t_w_firstyear.year_total > 0 THEN 
                   t_w_secyear.year_total / 
                   t_w_firstyear.year_total 
                   ELSE NULL 
                 END 
ORDER  BY t_s_secyear.customer_id, 
          t_s_secyear.customer_first_name, 
          t_s_secyear.customer_last_name, 
          t_s_secyear.customer_preferred_cust_flag
LIMIT 100; 

-- ============================================
-- TPC-DS Query 5
-- ============================================
-- start query 5 in stream 0 using template query5.tpl 
WITH ssr AS 
( 
         SELECT   s_store_id, 
                  Sum(sales_price) AS sales, 
                  Sum(profit)      AS profit, 
                  Sum(return_amt)  AS returns1, 
                  Sum(net_loss)    AS profit_loss 
         FROM     ( 
                         SELECT ss_store_sk             AS store_sk, 
                                ss_sold_date_sk         AS date_sk, 
                                ss_ext_sales_price      AS sales_price, 
                                ss_net_profit           AS profit, 
                                Cast(0 AS DECIMAL(7,2)) AS return_amt, 
                                Cast(0 AS DECIMAL(7,2)) AS net_loss 
                         FROM   store_sales 
                         UNION ALL 
                         SELECT sr_store_sk             AS store_sk, 
                                sr_returned_date_sk     AS date_sk, 
                                Cast(0 AS DECIMAL(7,2)) AS sales_price, 
                                Cast(0 AS DECIMAL(7,2)) AS profit, 
                                sr_return_amt           AS return_amt, 
                                sr_net_loss             AS net_loss 
                         FROM   store_returns ) salesreturns, 
                  date_dim, 
                  store 
         WHERE    date_sk = d_date_sk 
         AND      d_date BETWEEN Cast('2002-08-22' AS DATE) AND      ( 
                           Cast('2002-08-22' AS DATE) + INTERVAL '14' day) 
         AND      store_sk = s_store_sk 
         GROUP BY s_store_id) , csr AS 
( 
         SELECT   cp_catalog_page_id, 
                  sum(sales_price) AS sales, 
                  sum(profit)      AS profit, 
                  sum(return_amt)  AS returns1, 
                  sum(net_loss)    AS profit_loss 
         FROM     ( 
                         SELECT cs_catalog_page_sk      AS page_sk, 
                                cs_sold_date_sk         AS date_sk, 
                                cs_ext_sales_price      AS sales_price, 
                                cs_net_profit           AS profit, 
                                cast(0 AS decimal(7,2)) AS return_amt, 
                                cast(0 AS decimal(7,2)) AS net_loss 
                         FROM   catalog_sales 
                         UNION ALL 
                         SELECT cr_catalog_page_sk      AS page_sk, 
                                cr_returned_date_sk     AS date_sk, 
                                cast(0 AS decimal(7,2)) AS sales_price, 
                                cast(0 AS decimal(7,2)) AS profit, 
                                cr_return_amount        AS return_amt, 
                                cr_net_loss             AS net_loss 
                         FROM   catalog_returns ) salesreturns, 
                  date_dim, 
                  catalog_page 
         WHERE    date_sk = d_date_sk 
         AND      d_date BETWEEN cast('2002-08-22' AS date) AND      ( 
                           cast('2002-08-22' AS date) + INTERVAL '14' day) 
         AND      page_sk = cp_catalog_page_sk 
         GROUP BY cp_catalog_page_id) , wsr AS 
( 
         SELECT   web_site_id, 
                  sum(sales_price) AS sales, 
                  sum(profit)      AS profit, 
                  sum(return_amt)  AS returns1, 
                  sum(net_loss)    AS profit_loss 
         FROM     ( 
                         SELECT ws_web_site_sk          AS wsr_web_site_sk, 
                                ws_sold_date_sk         AS date_sk, 
                                ws_ext_sales_price      AS sales_price, 
                                ws_net_profit           AS profit, 
                                cast(0 AS decimal(7,2)) AS return_amt, 
                                cast(0 AS decimal(7,2)) AS net_loss 
                         FROM   web_sales 
                         UNION ALL 
                         SELECT          ws_web_site_sk          AS wsr_web_site_sk, 
                                         wr_returned_date_sk     AS date_sk, 
                                         cast(0 AS decimal(7,2)) AS sales_price, 
                                         cast(0 AS decimal(7,2)) AS profit, 
                                         wr_return_amt           AS return_amt, 
                                         wr_net_loss             AS net_loss 
                         FROM            web_returns 
                         LEFT OUTER JOIN web_sales 
                         ON              ( 
                                                         wr_item_sk = ws_item_sk 
                                         AND             wr_order_number = ws_order_number) ) salesreturns,
                  date_dim, 
                  web_site 
         WHERE    date_sk = d_date_sk 
         AND      d_date BETWEEN cast('2002-08-22' AS date) AND      ( 
                           cast('2002-08-22' AS date) + INTERVAL '14' day) 
         AND      wsr_web_site_sk = web_site_sk 
         GROUP BY web_site_id) 
SELECT 
         channel , 
         id , 
         sum(sales)   AS sales , 
         sum(returns1) AS returns1 , 
         sum(profit)  AS profit 
FROM     ( 
                SELECT 'store channel' AS channel , 
                       'store' 
                              || s_store_id AS id , 
                       sales , 
                       returns1 , 
                       (profit - profit_loss) AS profit 
                FROM   ssr 
                UNION ALL 
                SELECT 'catalog channel' AS channel , 
                       'catalog_page' 
                              || cp_catalog_page_id AS id , 
                       sales , 
                       returns1 , 
                       (profit - profit_loss) AS profit 
                FROM   csr 
                UNION ALL 
                SELECT 'web channel' AS channel , 
                       'web_site' 
                              || web_site_id AS id , 
                       sales , 
                       returns1 , 
                       (profit - profit_loss) AS profit 
                FROM   wsr ) x 
GROUP BY rollup (channel, id) 
ORDER BY channel , 
         id 
LIMIT 100; 

-- ============================================
-- TPC-DS Query 6
-- ============================================
-- start query 6 in stream 0 using template query6.tpl 
SELECT a.ca_state state, 
               Count(*)   cnt 
FROM   customer_address a, 
       customer c, 
       store_sales s, 
       date_dim d, 
       item i 
WHERE  a.ca_address_sk = c.c_current_addr_sk 
       AND c.c_customer_sk = s.ss_customer_sk 
       AND s.ss_sold_date_sk = d.d_date_sk 
       AND s.ss_item_sk = i.i_item_sk 
       AND d.d_month_seq = (SELECT DISTINCT ( d_month_seq ) 
                            FROM   date_dim 
                            WHERE  d_year = 1998 
                                   AND d_moy = 7) 
       AND i.i_current_price > 1.2 * (SELECT Avg(j.i_current_price) 
                                      FROM   item j 
                                      WHERE  j.i_category = i.i_category) 
GROUP  BY a.ca_state 
HAVING Count(*) >= 10 
ORDER  BY cnt
LIMIT 100; 

-- ============================================
-- TPC-DS Query 7
-- ============================================
-- start query 7 in stream 0 using template query7.tpl 
SELECT i_item_id, 
               Avg(ss_quantity)    agg1, 
               Avg(ss_list_price)  agg2, 
               Avg(ss_coupon_amt)  agg3, 
               Avg(ss_sales_price) agg4 
FROM   store_sales, 
       customer_demographics, 
       date_dim, 
       item, 
       promotion 
WHERE  ss_sold_date_sk = d_date_sk 
       AND ss_item_sk = i_item_sk 
       AND ss_cdemo_sk = cd_demo_sk 
       AND ss_promo_sk = p_promo_sk 
       AND cd_gender = 'F' 
       AND cd_marital_status = 'W' 
       AND cd_education_status = '2 yr Degree' 
       AND ( p_channel_email = 'N' 
              OR p_channel_event = 'N' ) 
       AND d_year = 1998 
GROUP  BY i_item_id 
ORDER  BY i_item_id
LIMIT 100; 

-- ============================================
-- TPC-DS Query 8
-- ============================================
-- start query 8 in stream 0 using template query8.tpl 
SELECT s_store_name, 
               Sum(ss_net_profit) 
FROM   store_sales, 
       date_dim, 
       store, 
       (SELECT ca_zip 
        FROM   (SELECT Substr(ca_zip, 1, 5) ca_zip 
                FROM   customer_address 
                WHERE  Substr(ca_zip, 1, 5) IN ( '67436', '26121', '38443', 
                                                 '63157', 
                                                 '68856', '19485', '86425', 
                                                 '26741', 
                                                 '70991', '60899', '63573', 
                                                 '47556', 
                                                 '56193', '93314', '87827', 
                                                 '62017', 
                                                 '85067', '95390', '48091', 
                                                 '10261', 
                                                 '81845', '41790', '42853', 
                                                 '24675', 
                                                 '12840', '60065', '84430', 
                                                 '57451', 
                                                 '24021', '91735', '75335', 
                                                 '71935', 
                                                 '34482', '56943', '70695', 
                                                 '52147', 
                                                 '56251', '28411', '86653', 
                                                 '23005', 
                                                 '22478', '29031', '34398', 
                                                 '15365', 
                                                 '42460', '33337', '59433', 
                                                 '73943', 
                                                 '72477', '74081', '74430', 
                                                 '64605', 
                                                 '39006', '11226', '49057', 
                                                 '97308', 
                                                 '42663', '18187', '19768', 
                                                 '43454', 
                                                 '32147', '76637', '51975', 
                                                 '11181', 
                                                 '45630', '33129', '45995', 
                                                 '64386', 
                                                 '55522', '26697', '20963', 
                                                 '35154', 
                                                 '64587', '49752', '66386', 
                                                 '30586', 
                                                 '59286', '13177', '66646', 
                                                 '84195', 
                                                 '74316', '36853', '32927', 
                                                 '12469', 
                                                 '11904', '36269', '17724', 
                                                 '55346', 
                                                 '12595', '53988', '65439', 
                                                 '28015', 
                                                 '63268', '73590', '29216', 
                                                 '82575', 
                                                 '69267', '13805', '91678', 
                                                 '79460', 
                                                 '94152', '14961', '15419', 
                                                 '48277', 
                                                 '62588', '55493', '28360', 
                                                 '14152', 
                                                 '55225', '18007', '53705', 
                                                 '56573', 
                                                 '80245', '71769', '57348', 
                                                 '36845', 
                                                 '13039', '17270', '22363', 
                                                 '83474', 
                                                 '25294', '43269', '77666', 
                                                 '15488', 
                                                 '99146', '64441', '43338', 
                                                 '38736', 
                                                 '62754', '48556', '86057', 
                                                 '23090', 
                                                 '38114', '66061', '18910', 
                                                 '84385', 
                                                 '23600', '19975', '27883', 
                                                 '65719', 
                                                 '19933', '32085', '49731', 
                                                 '40473', 
                                                 '27190', '46192', '23949', 
                                                 '44738', 
                                                 '12436', '64794', '68741', 
                                                 '15333', 
                                                 '24282', '49085', '31844', 
                                                 '71156', 
                                                 '48441', '17100', '98207', 
                                                 '44982', 
                                                 '20277', '71496', '96299', 
                                                 '37583', 
                                                 '22206', '89174', '30589', 
                                                 '61924', 
                                                 '53079', '10976', '13104', 
                                                 '42794', 
                                                 '54772', '15809', '56434', 
                                                 '39975', 
                                                 '13874', '30753', '77598', 
                                                 '78229', 
                                                 '59478', '12345', '55547', 
                                                 '57422', 
                                                 '42600', '79444', '29074', 
                                                 '29752', 
                                                 '21676', '32096', '43044', 
                                                 '39383', 
                                                 '37296', '36295', '63077', 
                                                 '16572', 
                                                 '31275', '18701', '40197', 
                                                 '48242', 
                                                 '27219', '49865', '84175', 
                                                 '30446', 
                                                 '25165', '13807', '72142', 
                                                 '70499', 
                                                 '70464', '71429', '18111', 
                                                 '70857', 
                                                 '29545', '36425', '52706', 
                                                 '36194', 
                                                 '42963', '75068', '47921', 
                                                 '74763', 
                                                 '90990', '89456', '62073', 
                                                 '88397', 
                                                 '73963', '75885', '62657', 
                                                 '12530', 
                                                 '81146', '57434', '25099', 
                                                 '41429', 
                                                 '98441', '48713', '52552', 
                                                 '31667', 
                                                 '14072', '13903', '44709', 
                                                 '85429', 
                                                 '58017', '38295', '44875', 
                                                 '73541', 
                                                 '30091', '12707', '23762', 
                                                 '62258', 
                                                 '33247', '78722', '77431', 
                                                 '14510', 
                                                 '35656', '72428', '92082', 
                                                 '35267', 
                                                 '43759', '24354', '90952', 
                                                 '11512', 
                                                 '21242', '22579', '56114', 
                                                 '32339', 
                                                 '52282', '41791', '24484', 
                                                 '95020', 
                                                 '28408', '99710', '11899', 
                                                 '43344', 
                                                 '72915', '27644', '62708', 
                                                 '74479', 
                                                 '17177', '32619', '12351', 
                                                 '91339', 
                                                 '31169', '57081', '53522', 
                                                 '16712', 
                                                 '34419', '71779', '44187', 
                                                 '46206', 
                                                 '96099', '61910', '53664', 
                                                 '12295', 
                                                 '31837', '33096', '10813', 
                                                 '63048', 
                                                 '31732', '79118', '73084', 
                                                 '72783', 
                                                 '84952', '46965', '77956', 
                                                 '39815', 
                                                 '32311', '75329', '48156', 
                                                 '30826', 
                                                 '49661', '13736', '92076', 
                                                 '74865', 
                                                 '88149', '92397', '52777', 
                                                 '68453', 
                                                 '32012', '21222', '52721', 
                                                 '24626', 
                                                 '18210', '42177', '91791', 
                                                 '75251', 
                                                 '82075', '44372', '45542', 
                                                 '20609', 
                                                 '60115', '17362', '22750', 
                                                 '90434', 
                                                 '31852', '54071', '33762', 
                                                 '14705', 
                                                 '40718', '56433', '30996', 
                                                 '40657', 
                                                 '49056', '23585', '66455', 
                                                 '41021', 
                                                 '74736', '72151', '37007', 
                                                 '21729', 
                                                 '60177', '84558', '59027', 
                                                 '93855', 
                                                 '60022', '86443', '19541', 
                                                 '86886', 
                                                 '30532', '39062', '48532', 
                                                 '34713', 
                                                 '52077', '22564', '64638', 
                                                 '15273', 
                                                 '31677', '36138', '62367', 
                                                 '60261', 
                                                 '80213', '42818', '25113', 
                                                 '72378', 
                                                 '69802', '69096', '55443', 
                                                 '28820', 
                                                 '13848', '78258', '37490', 
                                                 '30556', 
                                                 '77380', '28447', '44550', 
                                                 '26791', 
                                                 '70609', '82182', '33306', 
                                                 '43224', 
                                                 '22322', '86959', '68519', 
                                                 '14308', 
                                                 '46501', '81131', '34056', 
                                                 '61991', 
                                                 '19896', '87804', '65774', 
                                                 '92564' ) 
                INTERSECT 
                SELECT ca_zip 
                FROM   (SELECT Substr(ca_zip, 1, 5) ca_zip, 
                               Count(*)             cnt 
                        FROM   customer_address, 
                               customer 
                        WHERE  ca_address_sk = c_current_addr_sk 
                               AND c_preferred_cust_flag = 'Y' 
                        GROUP  BY ca_zip 
                        HAVING Count(*) > 10)A1)A2) V1 
WHERE  ss_store_sk = s_store_sk 
       AND ss_sold_date_sk = d_date_sk 
       AND d_qoy = 2 
       AND d_year = 2000 
       AND ( Substr(s_zip, 1, 2) = Substr(V1.ca_zip, 1, 2) ) 
GROUP  BY s_store_name 
ORDER  BY s_store_name
LIMIT 100; 

-- ============================================
-- TPC-DS Query 9
-- ============================================
-- start query 9 in stream 0 using template query9.tpl 
SELECT CASE 
         WHEN (SELECT Count(*) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 1 AND 20) > 3672 THEN 
         (SELECT Avg(ss_ext_list_price) 
          FROM   store_sales 
          WHERE 
         ss_quantity BETWEEN 1 AND 20) 
         ELSE (SELECT Avg(ss_net_profit) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 1 AND 20) 
       END bucket1, 
       CASE 
         WHEN (SELECT Count(*) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 21 AND 40) > 3392 THEN 
         (SELECT Avg(ss_ext_list_price) 
          FROM   store_sales 
          WHERE 
         ss_quantity BETWEEN 21 AND 40) 
         ELSE (SELECT Avg(ss_net_profit) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 21 AND 40) 
       END bucket2, 
       CASE 
         WHEN (SELECT Count(*) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 41 AND 60) > 32784 THEN 
         (SELECT Avg(ss_ext_list_price) 
          FROM   store_sales 
          WHERE 
         ss_quantity BETWEEN 41 AND 60) 
         ELSE (SELECT Avg(ss_net_profit) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 41 AND 60) 
       END bucket3, 
       CASE 
         WHEN (SELECT Count(*) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 61 AND 80) > 26032 THEN 
         (SELECT Avg(ss_ext_list_price) 
          FROM   store_sales 
          WHERE 
         ss_quantity BETWEEN 61 AND 80) 
         ELSE (SELECT Avg(ss_net_profit) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 61 AND 80) 
       END bucket4, 
       CASE 
         WHEN (SELECT Count(*) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 81 AND 100) > 23982 THEN 
         (SELECT Avg(ss_ext_list_price) 
          FROM   store_sales 
          WHERE 
         ss_quantity BETWEEN 81 AND 100) 
         ELSE (SELECT Avg(ss_net_profit) 
               FROM   store_sales 
               WHERE  ss_quantity BETWEEN 81 AND 100) 
       END bucket5 
FROM   reason 
WHERE  r_reason_sk = 1; 

-- ============================================
-- TPC-DS Query 10
-- ============================================
-- start query 10 in stream 0 using template query10.tpl 
SELECT cd_gender, 
               cd_marital_status, 
               cd_education_status, 
               Count(*) cnt1, 
               cd_purchase_estimate, 
               Count(*) cnt2, 
               cd_credit_rating, 
               Count(*) cnt3, 
               cd_dep_count, 
               Count(*) cnt4, 
               cd_dep_employed_count, 
               Count(*) cnt5, 
               cd_dep_college_count, 
               Count(*) cnt6 
FROM   customer c, 
       customer_address ca, 
       customer_demographics 
WHERE  c.c_current_addr_sk = ca.ca_address_sk 
       AND ca_county IN ( 'Lycoming County', 'Sheridan County', 
                          'Kandiyohi County', 
                          'Pike County', 
                                           'Greene County' ) 
       AND cd_demo_sk = c.c_current_cdemo_sk 
       AND EXISTS (SELECT * 
                   FROM   store_sales, 
                          date_dim 
                   WHERE  c.c_customer_sk = ss_customer_sk 
                          AND ss_sold_date_sk = d_date_sk 
                          AND d_year = 2002 
                          AND d_moy BETWEEN 4 AND 4 + 3) 
       AND ( EXISTS (SELECT * 
                     FROM   web_sales, 
                            date_dim 
                     WHERE  c.c_customer_sk = ws_bill_customer_sk 
                            AND ws_sold_date_sk = d_date_sk 
                            AND d_year = 2002 
                            AND d_moy BETWEEN 4 AND 4 + 3) 
              OR EXISTS (SELECT * 
                         FROM   catalog_sales, 
                                date_dim 
                         WHERE  c.c_customer_sk = cs_ship_customer_sk 
                                AND cs_sold_date_sk = d_date_sk 
                                AND d_year = 2002 
                                AND d_moy BETWEEN 4 AND 4 + 3) ) 
GROUP  BY cd_gender, 
          cd_marital_status, 
          cd_education_status, 
          cd_purchase_estimate, 
          cd_credit_rating, 
          cd_dep_count, 
          cd_dep_employed_count, 
          cd_dep_college_count 
ORDER  BY cd_gender, 
          cd_marital_status, 
          cd_education_status, 
          cd_purchase_estimate, 
          cd_credit_rating, 
          cd_dep_count, 
          cd_dep_employed_count, 
          cd_dep_college_count
LIMIT 100; 


