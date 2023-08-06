DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_api`(IN `paramsJson` JSON)
BEGIN
   	SET @vUsuario = JSON_VALUE(paramsJson,'$.usu');
    INSERT INTO api (text_json, fecha, usuario_id) VALUES(paramsJson, now(), @vUsuario);
    SELECT LAST_INSERT_ID() id;
END$$
DELIMITER ;