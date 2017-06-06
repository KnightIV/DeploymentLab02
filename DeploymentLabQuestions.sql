/***************************** Deployment Lab *********************************

Instructions
------------

Run the DeploymentLabSetup.sql script to create three databases representative 
of the different customer database states: DeploymentA, DeploymentB, DeploymentC.  

Due to the nature of the grading rubric for this lab, your script _must_ be able 
to execute on a single database by running the entire script with no text selected.

Make sure your entire script parses and runs!

The Scenario:
-------------

The "Deployment" (Northwind) database is deployed to hundreds of franchises worldwide, 
and it is one of several databases behind a larger application.

Each franchise owner can add and remove rows to any table in the database.  
An owner can, for example, add suppliers or products, in addition to adding 
customers, orders, and order details.  

You previously and mistakenly released a patch that inconsistently
updated customers' databases.  On some databases, the update succeeded, on others
it partially succeeded, and on others it has not run yet.

Your task is to release another patch that appropriately brings all franchise
databases up to date, regardless of how much of the previous patch was 
successful.

The DeploymentX databases are based on the TSQL2012 / Northwind database we've been using in class.

Rubric
------

I'll take your script, add a "Use DeploymentA/B/C" at the top, then run it.  Your
script should succeed on DeploymentA and B.  In DeploymentC,
which represents a database changed beyond your company's service agreement,
your script will fail and must roll back any changes it made previous to the failure
point.

After running your script on the three databases, I'll run an automated test 
to ensure the script successfully completed all the tasks in each question for A and B, 
and successfully rolled back on C.

This is what "all succeed or all fail" or "atomicity" means.

You earn points by completing/rolling back gracefully and handling expected database 
differences described in each question.


**********************************************************************************/
set xact_abort on 
begin tran
	/* 1.1
	Remove the following tables from the database, if they exist:
		CustomersBU
		OrderDetailsBU
		OrderDetailsBU2
	*/
	if exists (select * from sys.tables where name = 'CustomersBU')
		begin
			drop table CustomersBU;
		end

	if exists (select * from sys.tables where name = 'OrderDetailsBU')
		begin
			drop table CustomersBU;
		end

	if exists (select * from sys.tables where name = 'OrderDetailsBU2')
		begin
			drop table CustomersBU;
		end

	/* 2.1
	Testing data was mistakenly pushed out to production.  All data for any customer
	with a customerid higher than 10000 is testing data, and should be removed
	from production databases.  Ensure all data associated with these customers
	is removed from the database.
	*/
	delete from Customers
	where custid > 10000

	/* 3.1
	If it has not already been added, add a new category to the Categories 
	table called Spices.
	*/
	if not exists (Select * from Categories Where categoryname = 'Spices')
		begin
			insert into Categories(categoryname, description)
			Values ('Spices', 'Stuff that makes your food taste good')
		end;

	/* 3.2
	If it has not already been added, add a new supplier called "The Spice
	Supplier".  Use appropriate values for all other columns in the new record.
	*/
	if not exists (select * from Suppliers where companyname = 'The Spice Supplier')
		begin
			insert into Suppliers(companyname, contactname, contacttitle, [address],
				city, country, phone)
			values('The Spice Supplier', 'Matt Damon', 'Spicy Director', '2403 Davenmoor Dr.', 
				'Katy','USA', '333-867-5309')
		end

	/* 3.3
	Add the following products under the spices category if they have not already
	been added:
		Cinnamon
		Paprika
		Cayenne Pepper
		Bay Leaves	
	
	All these spices will be supplied by the new supplier you added above.  You 
	may not hard code the supplierid or categoryid on your insert commands.
	Hard coding could break in databases that have already used the value 
	you hard code for a different row.
	*/
	declare @SupplierID as int;
	set @SupplierID = (select supplierid from Suppliers where companyname = 'The Spice Supplier')

	declare @CategoryID as int;
	set @CategoryID = (select categoryid from Categories where categoryname = 'Spices')

	if not exists (Select * from Products Where productname = 'Cinnamon')
		begin
			insert into Products(productname, supplierid, categoryid, unitprice, discontinued)
			values('Cinnamon', @SupplierID, @CategoryID, 2.00, 0)
		end
	if not exists (Select * from Products Where productname = 'Paprika')
		begin
			insert into Products(productname, supplierid, categoryid, unitprice, discontinued)
			values('Paprika', @SupplierID, @CategoryID, 3.00, 0)
		end
	if not exists (Select * from Products Where productname = 'Cayenne Pepper')
		begin
			insert into Products(productname, supplierid, categoryid, unitprice, discontinued)
			values('Cayenne Pepper', @SupplierID, @CategoryID, 2.50, 0)
		end
	if not exists (Select * from Products Where productname = 'Bay Leaves')
		begin
			insert into Products(productname, supplierid, categoryid, unitprice, discontinued)
			values('Bay Leaves', @SupplierID, @CategoryID, 2.75, 0)
		end

	/* 3.4
	A different update script may have incorrectly added these new products under supplierid 1.  
	Ensure that when your full script is complete the supplier for these
	4 new products is accurate (you can use multiple commands to do so).
	*/
	if ((select supplierid from Products where productname = 'Cinnamon') != @SupplierID)
		begin
			update Products
			set supplierid = @SupplierID
			where productname = 'Cinnamon'
		end

	if ((select supplierid from Products where productname = 'Paprika') != @SupplierID)
		begin
			update Products
			set supplierid = @SupplierID
			where productname = 'Paprika'
		end

	if ((select supplierid from Products where productname = 'Cayenne Pepper') != @SupplierID)
		begin
			update Products
			set supplierid = @SupplierID
			where productname = 'Cayenne Pepper'
		end

	if ((select supplierid from Products where productname = 'Bay Leaves') != @SupplierID)
		begin
			update Products
			set supplierid = @SupplierID
			where productname = 'Bay Leaves'
		end


	/* 4.1
	If it has not already been added, add a bit column named Organic to the
	Products table.  The default for this column is 0.
	*/
	if not exists (Select * from sys.columns Where Name = N'Organic')
		begin 
			alter table Products
				ADD Organic bit default 0 Not Null; 
		end

	/* 4.2
	Only the following suppliers provide organic goods, and all the products
	they supply are organic.  Update the products table so the entire table
	has accurate data for the Organic column.

	Supplier CIYNM
	Supplier EQPNC
	Supplier ZRYDZ
	Supplier ZPYVS
	Supplier BWGYE
	Supplier GQRCV

	*/
	Update Products
	set Organic = 1
	where Products.supplierid in (select supplierID from Suppliers 
								where companyname in ('Supplier CIYNM', 
								'Supplier EQPNC', 'Supplier ZRYDZ',
								'Supplier ZPYVS','Supplier BWGYE','Supplier GQRCV'));

	/* 5.1
	Add addDate, addUser, modDate, modUser fields to the Products table.
	These are the "audit fields" referred to in subsequent questions.
	*/
	alter table products
		add addDate date;

	alter table products
		add addUser int;

	alter table products
		add modDate date;

	alter table products
		add modUser int;

	/* 5.2
	Add an audit trigger to the Products table.

	An audit trigger will keep the four audit fields from Q5.1 accurate regardless
	of what a user tries to set them to.

	The audit trigger will handle inserts and updates, but do nothing on deletes.
	*/
	go 

	create trigger tr_Products_Insert
	on Products for insert, update
	as
		if ((select modUser from inserted) is null)
			begin
				print 'modUser cannot be null'
				rollback tran;
			end

	go

	/* 6.1
	Create a stored procedure that returns the products
	whose data changed between a date range specified by parameters.
	*/
	go
	create procedure dateRange
		@firstDate date,
		@secondDate date
	as
		Select * from Products
		where modDate >= @firstDate and modDate <= @secondDate
	go
end tran