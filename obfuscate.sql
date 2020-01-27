/*####################################################################################################
				##################################################
				WARNING: DO NOT RUN ON PRODUCTION DATABASES !!!!!
				##################################################

				Author: Sahil Narain
		
			This script is used to obfuscate SPI (Sensitive Personal Information).		
			
			This MUST necessarily be run when production data is refreshed on staging/dev/
			
####################################################################################################*/

USE ##DBNAME - intentionally left out. The script will not work unless a database name is specified. Done so you check the environment before running the script :)
;

DROP PROCEDURE IF EXISTS mask;
DELIMITER //

CREATE PROCEDURE  mask(tableName LONGTEXT, columnName LONGTEXT, padding INT, excludeFieldName LONGTEXT, excludeFieldValues LONGTEXT)
BEGIN
	SET @statement=CONCAT('UPDATE ', tableName, ' SET ', columnName, '=REPLACE(', columnName, ', SUBSTRING(', columnName, ', ', (padding+1), ', LENGTH(', columnName, ')-', (padding*2), '), REPEAT("x", LENGTH(', columnName, ')-', padding, ')) WHERE NOT FIND_IN_SET(', excludeFieldName, ', ("', excludeFieldValues, '"));');
/* 	SELECT @statement as ''; */
	PREPARE dynamicSql FROM @statement;
	EXECUTE dynamicSql;
	DEALLOCATE PREPARE dynamicSql;
END//

//
// DELIMITER ;

#######
#######

/* Example usage

## Set phone numbers to exclude and set collation according to DB
SELECT @excludePhones:="<10-digit-phone-number-1>,<10-digit-phone-number-2>.....";# COLLATE utf8mb4_unicode_ci;
## SELECT @excludePhones:="<10-digit-phone-number-1>,<10-digit-phone-number-2>....." COLLATE utf8mb4_unicode_ci; -- Depends on where it's being copied from - ideally put it in a plain text editor and strip it off

## Get user ids to exclude
SELECT @excludeUserIds:=GROUP_CONCAT(id) FROM users WHERE FIND_IN_SET(phone, @excludePhones);

## Check tables which reference users
# SELECT * FROM information_schema.columns WHERE COLUMN_NAME='user_id' and TABLE_SCHEMA='baxi';

## Addresses
CALL mask('addresses', 'street_address', 1, 'user_id', @excludeUserIds);
CALL mask('addresses', 'sublocality', 1, 'user_id', @excludeUserIds);
CALL mask('addresses', 'locality', 1, 'user_id', @excludeUserIds);
CALL mask('addresses', 'landmark', 1, 'user_id', @excludeUserIds);

## Bank Accounts
CALL mask('bank_accounts', 'beneficiary_name', 1, 'user_id', @excludeUserIds);
CALL mask('bank_accounts', 'ifsc', 1, 'user_id', @excludeUserIds);
CALL mask('bank_accounts', 'beneficiary_account_number', 1, 'user_id', @excludeUserIds);
CALL mask('bank_accounts', 'beneficiary_email', 1, 'user_id', @excludeUserIds);
CALL mask('bank_accounts', 'beneficiary_mobile', 1, 'user_id', @excludeUserIds);
...

## Ledgers
CALL mask('ledgers', 'description', 1, 'user_id', @excludeUserIds);
CALL mask('ledgers', 'description', 1, 'to_user_id', @excludeUserIds);
...

# Orders
CALL mask('orders', 'origin_street_address', 1, 'user_id', @excludeUserIds);
CALL mask('orders', 'origin_sublocality', 1, 'user_id', @excludeUserIds);
CALL mask('orders', 'origin_locality', 1, 'user_id', @excludeUserIds);
CALL mask('orders', 'origin_landmark', 1, 'user_id', @excludeUserIds);
CALL mask('orders', 'comments', 1, 'user_id', @excludeUserIds);
...

# Sessions
CALL mask('sessions', 'token', 6, 'user_id', @excludeUserIds);
...

# Users
CALL mask('users', 'first_name', 1, 'id', @excludeUserIds);
CALL mask('users', 'last_name', 1, 'id', @excludeUserIds);
CALL mask('users', 'gender', 0, 'id', @excludeUserIds);
#CALL mask('users', 'phone', 0, 'id', @excludeUserIds);
#CALL mask('users', 'email', 0, 'id', @excludeUserIds);
CALL mask('users', 'password', 0, 'id', @excludeUserIds);
...

## Can not mask specifics because of high collisions in unique fields 

# Users - Phone
SELECT @statement:=concat('UPDATE users SET phone=concat("P_", id) WHERE id NOT IN (', @excludeUserIds,')');
PREPARE dynamicSql FROM @statement;
EXECUTE dynamicSql;
DEALLOCATE PREPARE dynamicSql;

# Users - Email (Specific email)
SELECT @statement:=concat('UPDATE users SET email=concat("E_", id) WHERE id NOT IN (', @excludeUserIds,')');
PREPARE dynamicSql FROM @statement;
EXECUTE dynamicSql;
DEALLOCATE PREPARE dynamicSql;

*/
