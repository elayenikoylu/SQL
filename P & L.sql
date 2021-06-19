USE H_Accounting;

-- A stored procedure, or a stored routine, is like a function in other programming languages
-- We write the code once, and the code can de reused over and over again
-- We can pass on arguments into the stored procedure. i.e. we can give a specific input to a store procedure
-- For example we could determine the specific for which we want to produce the profit and loss statement


#  FIRST thing you MUST do whenever writting a stored procedure is to change the DELIMTER
#  The default deimiter in SQL is the semicolon ;
#  Since we will be using the semicolon to start and finish sentences inside the stored procedure
#  The compiler of SQL won't know if the semicolon is closing the entire Stored procedure or an line inside
#  Therefore, we change the DELIMITER so we can be explicit about whan we are closing the stored procedure, vs. when
#  we are closing a specific Select  command

#DROP PROCEDURE IF EXISTS `jwhanglee2020_sp`;
-- The tpycal delimiter for Stored procedures is a double dollar sign
DELIMITER $$

	CREATE PROCEDURE `jwhanglee2020_sp`(varCalendarYear YEAR)
	BEGIN
  
  
  
		-- We receive as an argument the year for which we will calculate the revenues
    -- This value is stored as an 'YEAR' type in the variable `varCalendarYear`
    -- To avoid confusion among which are fields from a table vs. which are the variables
    -- A good practice is to adopt a naming convention for all variables
    -- In these lines of code we are naming prefixing every variable as "var"
	
  
		-- We can define variables inside of our procedure
		DECLARE varTotalRevenues, 
			    varCGS,
                varOtherExpenses,
                varSellingExpenses,
                varIncomeTax DOUBLE DEFAULT 0;
  
		--  Total Revenue
		SELECT (CASE WHEN ROUND(SUM(jeli.credit), 2) IS NULL THEN 0 ELSE ROUND(SUM(jeli.debit), 2) END) INTO varTotalRevenues
		
			FROM journal_entry_line_item AS jeli
		
				INNER JOIN account 						AS ac ON ac.account_id = jeli.account_id
				INNER JOIN journal_entry 			AS je ON je.journal_entry_id = jeli.journal_entry_id
				INNER JOIN statement_section	AS ss ON ss.statement_section_id = ac.profit_loss_section_id
      
			WHERE ss.statement_section_code = "REV"
				AND YEAR(je.entry_date) = varCalendarYear;
  
  		--  Total CGS
		SELECT (CASE WHEN ROUND(SUM(jeli.debit), 2) IS NULL THEN 0 ELSE ROUND(SUM(jeli.debit), 2) END) INTO varCGS
		
			FROM journal_entry_line_item AS jeli
		
				INNER JOIN account 						AS ac ON ac.account_id = jeli.account_id
				INNER JOIN journal_entry 			AS je ON je.journal_entry_id = jeli.journal_entry_id
				INNER JOIN statement_section	AS ss ON ss.statement_section_id = ac.profit_loss_section_id
      
			WHERE ss.statement_section_code = "COGS"
				AND YEAR(je.entry_date) = varCalendarYear;
			
		--  Total Other Expenses
		SELECT (CASE WHEN ROUND(SUM(jeli.debit), 2) IS NULL THEN 0 ELSE ROUND(SUM(jeli.debit), 2) END) INTO varOtherExpenses
		
			FROM journal_entry_line_item AS jeli
		
				INNER JOIN account 						AS ac ON ac.account_id = jeli.account_id
				INNER JOIN journal_entry 			AS je ON je.journal_entry_id = jeli.journal_entry_id
				INNER JOIN statement_section	AS ss ON ss.statement_section_id = ac.profit_loss_section_id
      
			WHERE ss.statement_section_code = "OEXP"
				AND YEAR(je.entry_date) = varCalendarYear;
                
		--  Total Selling Expenses
		SELECT ROUND(SUM(jeli.debit), 2) INTO varSellingExpenses
		
			FROM journal_entry_line_item AS jeli
		
				INNER JOIN account 						AS ac ON ac.account_id = jeli.account_id
				INNER JOIN journal_entry 			AS je ON je.journal_entry_id = jeli.journal_entry_id
				INNER JOIN statement_section	AS ss ON ss.statement_section_id = ac.profit_loss_section_id
      
			WHERE ss.statement_section_code = "SEXP"
				AND YEAR(je.entry_date) = varCalendarYear;
                
		--  Total Income Tax
		SELECT (CASE WHEN ROUND(SUM(jeli.debit), 2) IS NULL THEN 0 ELSE ROUND(SUM(jeli.debit), 2) END) INTO varIncomeTax
		
			FROM journal_entry_line_item AS jeli
		
				INNER JOIN account 						AS ac ON ac.account_id = jeli.account_id
				INNER JOIN journal_entry 			AS je ON je.journal_entry_id = jeli.journal_entry_id
				INNER JOIN statement_section	AS ss ON ss.statement_section_id = ac.profit_loss_section_id
      
			WHERE ss.statement_section_code = "INCTAX"
				AND YEAR(je.entry_date) = varCalendarYear;
                
		
    		-- Let's drop the `tmp` table where we will input the revenue
		-- The IF EXISTS is important. Because if the table does not exist the DROP alone would fail
		-- A store procedure will stop running whenever it faces an error. 
		DROP TABLE IF EXISTS tmp_jwhanglee2020_table;
  
		-- Now we are certain that the table does not exist, we create with the columns that we need
		CREATE TABLE tmp_jwhanglee2020_table
		( profit_loss_line_number INT, 
			label VARCHAR(50), 
			amount VARCHAR(50)
		);
  
  -- REVENUE LABEL
  INSERT INTO tmp_jwhanglee2020_table 
		(profit_loss_line_number, label, amount)
		VALUES (1, 'Revenue', FORMAT(varTotalRevenues, 2));
  
  -- CGS LABEL
	INSERT INTO tmp_jwhanglee2020_table 
		(profit_loss_line_number, label, amount)
  		VALUES (2, 'Cost of Good Sold', FORMAT(varCGS, 2));
    
	-- OTHER EXPENSES LABEL
	INSERT INTO tmp_jwhanglee2020_table 
		(profit_loss_line_number, label, amount)
  		VALUES (3, 'Other Expenses', FORMAT(varOtherExpenses, 2));
        
	-- SELLING EXPENSES LABEL
	INSERT INTO tmp_jwhanglee2020_table 
		(profit_loss_line_number, label, amount)
  		VALUES (4, 'Selling Expenses', FORMAT(varSellingExpenses, 2));
        
	-- INCOME TAX LABEL
	INSERT INTO tmp_jwhanglee2020_table 
		(profit_loss_line_number, label, amount)
  		VALUES (5, 'Income Tax', FORMAT(varIncomeTax, 2));
        
	-- PROFIT LABEL
	INSERT INTO tmp_jwhanglee2020_table 
		(profit_loss_line_number, label, amount)
  		VALUES (6, 'Profit', FORMAT((varTotalRevenues - varCGS - varOtherExpenses - varSellingExpenses - varIncomeTax), 2));
	
    
	END $$

DELIMITER ;

CALL jwhanglee2020_sp(2016);

SELECT * FROM tmp_jwhanglee2020_table;