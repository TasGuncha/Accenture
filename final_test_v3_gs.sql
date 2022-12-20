--==================================================== [ Final Task V3 ] =====================================================--
/*
    FOR TESTING PURPOSES, PLEASE DELETE ALL 2 AFTER TABLE_NAME
    (e.g. Accounts NOT Accounts2, Operations NOT Operations2)
    I have the different table names. In the beggining of 02-MAR -> 06-MAR
    week, I created new tables, adding number 2 by their original names!!!
*/
DECLARE
    -- Atsaucoties uz praktiskajiem uzdevumiem (PL/SQL. Exercise-2)
    l_period_start_date DATE;
    l_period_end_date DATE;
    -- Kredīti/Debeti
    l_start_balance number;
    type t_total_amount is record(
        credit number := 0,
        debit number := 0);
    l_total_amount t_total_amount;
    /*
        Ja sadala pa blokiem, tad rezultātā vajadzētu būt 3 tādiem:
        -1.-pilna adrese, pilnais vārds, nr.(reģistrācijas/pers.kods)
        -2.-konti
        -3.-visas operācijas zem katra konta
    */
    --1.bloks:
    CURSOR cur_customers_info IS
        SELECT * FROM Parties2 p, Addresses2 ad
        WHERE p.id_no = ad.party_id
        ORDER BY p.party_type ASC, p.forename ASC, p.registration_no ASC;
    --2.bloks:
    CURSOR cur_customers_accounts (l_p_id Parties2.id_no%type) IS
        SELECT * FROM Accounts2 ac
        WHERE l_p_id = ac.party_id;
    --3.bloks;
    CURSOR cur_customers_operations (l_account_no Accounts2.account_no%type, l_start_date DATE, l_end_date DATE) IS
        SELECT o.*, ol.operation_type
        FROM Operations2 o, Operations_log2 ol
        WHERE o.operation_id = ol.operation_id
            AND o.account_no = l_account_no
            AND ol.status = 'OK'
            AND trunc(ol.timestamp) >= trunc(l_start_date)
            AND trunc(ol.timestamp) <= trunc(l_end_date);
    /*
        Tiek veidotas 3 procedūras, lai vieglāk attēlotu datus
        par katru no kursoriem begin-end sadaļā;
        Atsauce uz prezentācijas v07_8 pēdējiem slaidiem (print_results).
    */
    PROCEDURE print_results_customer(l_customer cur_customers_info%rowtype, l_start_date DATE, l_end_date DATE) IS
    BEGIN
        IF l_customer.apartment IS NULL THEN
            dbms_output.put_line(rpad(to_char(l_start_date, 'DD-MON-YYYY HH:MI:SS AM')||' - '||to_char(l_end_date, 'DD-MON-YYYY HH:MI:SS AM'), 50)||lpad(l_customer.street||' '||l_customer.house||', '||l_customer.city||', '||l_customer.country||', '||l_customer.post_code, 88));
        ELSE
            dbms_output.put_line(rpad(to_char(l_start_date, 'DD-MON-YYYY HH:MI:SS AM')||' - '||to_char(l_end_date, 'DD-MON-YYYY HH:MI:SS AM'), 50)||lpad(l_customer.street||' '||l_customer.house||', '||l_customer.city||', '||l_customer.country||', '||l_customer.post_code, 88));
        END IF;
        IF l_customer.party_type = 1 THEN
            dbms_output.put_line(rpad(initcap(l_customer.forename)||' '||initcap(l_customer.name), 50)||lpad('Registration '||l_customer.civil_reg_code, 88));
        ELSE
            dbms_output.put_line(rpad(initcap(l_customer.name), 50)||lpad('Registration '||l_customer.registration_no, 88));
        END IF;
    END;
    PROCEDURE print_results_operations(l_operation cur_customers_operations%rowtype) IS
    BEGIN
        IF l_operation.operation_type = 'CC_PAYMENT' THEN
            dbms_output.put_line(lpad(to_char(l_operation.timestamp, 'DD-MON-YYYY HH:MI:SS AM')||', '||l_operation.operation_type, 45)||lpad('-'||to_char(l_operation.amount, 'FM99990.00'), 93));
        ELSE
            dbms_output.put_line(lpad(to_char(l_operation.timestamp, 'DD-MON-YYYY HH:MI:SS AM')||', '||l_operation.operation_type, 45)||lpad('+'||to_char(l_operation.amount, 'FM99990.00'), 93));
        END IF;
    END;
    procedure print_debit_credit(p_total_amount t_total_amount)
    is
    begin
        --dbms_output.put_line(rpad(lpad('Credit/Debit'||'  |  '||l_total_amount.credit||'/'||l_total_amount.debit, 27), 30));
        dbms_output.put_line(lpad('Credit/Debit', 19)||lpad(to_char(l_total_amount.credit, 'FM99990.00')||'/'||to_char(l_total_amount.debit, 'FM99990.00'), 119));
    end;
BEGIN
    /*
        -BEGIN daļa uzrādīsies gatavā atskaite par norādīto laika posmu;
        -3 LOOP'i, katrs iet cauri, atsaucoties uz definēto kursoru DECLARE daļā.
    */
    l_period_start_date := to_date(:period_start_date);
    l_period_end_date := to_date(:period_end_date);
    dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------');
    dbms_output.put_line(lpad('Customer report', 75));
    dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------');
    FOR i IN cur_customers_info LOOP
        print_results_customer(i, l_period_start_date, l_period_end_date);
        FOR j IN cur_customers_accounts (i.id_no) LOOP
            dbms_output.put_line(rpad(CHR(9)||'Account '||j.account_type||', NR.'||j.account_no, 27));
            dbms_output.put_line(rpad(lpad('Balance on '||l_period_end_date, 27), 30));
            FOR k IN cur_customers_operations (j.account_no, l_period_start_date, l_period_end_date) LOOP
                IF k.operation_type = 'CC_PAYMENT' THEN
                    l_total_amount.credit := l_total_amount.credit + k.amount;
                ELSE
                    l_total_amount.debit := l_total_amount.credit + k.amount;
                END IF;
                print_results_operations(k);
            END LOOP;
            dbms_output.put_line(rpad(lpad('Balance on '||l_period_end_date, 27), 30));
            print_debit_credit(l_total_amount);
            l_total_amount.credit := 0;
            l_total_amount.debit := 0;
            dbms_output.put_line(lpad(rpad('------------------------------------------------------------------------', 49), 138));
            dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------');
        END LOOP;
        dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------');
    END LOOP;
    dbms_output.put_line(lpad('End of report', 75));
    dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------');
END;
/