USE lesson_4;
-- Создайте таблицу users_old, аналогичную таблице users.

DROP TABLE IF EXISTS users_old;
CREATE TABLE users_old
(
	id SERIAL PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50) COMMENT 'FirstName',
    email VARCHAR(120) UNIQUE
);

-- Создайте процедуру, с помощью которой можно переместить любого (одного)
-- пользователя из таблицы users в таблицу users_old.
-- (использование транзакции с выбором commit или rollback – обязательно).

DROP PROCEDURE IF EXISTS sp_user_move;
DELIMITER //
CREATE PROCEDURE sp_user_move
(
	IN user_id BIGINT,
	OUT tran_result varchar(100)
)
DETERMINISTIC
BEGIN

	DECLARE `_rollback` BIT DEFAULT b'0';
	DECLARE code varchar(100);
	DECLARE error_string varchar(100);

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
 		SET `_rollback` = b'1';
 		GET stacked DIAGNOSTICS CONDITION 1
			code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
	END;

	START TRANSACTION;
	 INSERT INTO lesson_4.users_old (firstname, lastname, email)
	 SELECT firstname, lastname, email
	 FROM lesson_4.users
	 WHERE id = user_id;
	 DELETE FROM lesson_4.users
	 WHERE id = user_id;

	IF `_rollback` THEN
		SET tran_result = CONCAT('ERROR: ', code, 'ERROR Comments: ', error_string);
		ROLLBACK;
	ELSE
		SET tran_result = 'OK';
		COMMIT;
	END IF;
END//
DELIMITER ;

SELECT * FROM users;
SELECT * FROM users_old;
CALL sp_user_move(1, @tran_result);
SELECT @tran_result;

-- Создайте хранимую функцию hello(), которая будет возвращать приветствие,
-- в зависимости от текущего времени суток. С 6:00 до 12:00 функция должна возвращать
-- фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать фразу "Добрый день",
-- с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".

DROP FUNCTION IF EXISTS hello;
DELIMITER //
CREATE FUNCTION hello()
RETURNS VARCHAR(12) READS SQL DATA
BEGIN
	DECLARE res_text VARCHAR(12);
	SELECT
		CASE
			WHEN CURTIME() BETWEEN '06:00:00' AND '11:59:59' THEN 'Доброе утро'
			WHEN CURTIME() BETWEEN '12:00:00' AND '17:59:59' THEN 'Добрый день'
			WHEN CURTIME() BETWEEN '18:00:00' AND '23:59:59' THEN 'Добрый вечер'
			ELSE 'Доброй ночи'
	END INTO res_text;
	RETURN res_text;
END//
DELIMITER ;

SELECT hello();

-- (по желанию)* Создайте таблицу logs типа Archive. Пусть при каждом создании записи
-- в таблицах users, communities и messages в таблицу logs помещается время и дата
-- создания записи, название таблицы, идентификатор первичного ключа.

DROP TABLE IF EXISTS logs;
CREATE TABLE logs
(
	date_and_time DATETIME DEFAULT NOW(),
	table_name VARCHAR(15) NOT NULL,
	p_key_id BIGINT UNSIGNED NOT NULL
)
ENGINE = ARCHIVE;

DROP TRIGGER if exists users_table_log;
CREATE TRIGGER users_table_log
AFTER INSERT
ON users FOR EACH ROW
INSERT INTO logs SET table_name = 'users', p_key_id = NEW.id;

INSERT INTO users (firstname, lastname, email)
VALUES ('Sergey', 'Churikov-SV', 'SVchurikov@mail.ru');
SELECT * FROM logs;

DROP TRIGGER if exists communities_table_log;
CREATE TRIGGER communities_table_log
AFTER INSERT
ON users FOR EACH ROW
INSERT INTO logs SET table_name = 'communities', p_key_id = NEW.id;

INSERT INTO communities (name)
VALUES ('communitie1');
SELECT * FROM logs;

CREATE TRIGGER messages_t_log
AFTER INSERT
ON messages FOR EACH ROW
INSERT INTO logs SET table_name = 'messages', p_key_id = NEW.id;