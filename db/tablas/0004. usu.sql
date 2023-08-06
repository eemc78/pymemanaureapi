CREATE TABLE `usu` ( 
	`id` BIGINT(30) UNSIGNED NOT NULL AUTO_INCREMENT,   
	`grupo_id` BIGINT(30) UNSIGNED NOT NULL,    
	`usuario` VARCHAR(60) NOT NULL,  
	`clave` VARCHAR(255) NOT NULL,  
	`nombres` VARCHAR(160) NOT NULL,  
	`apellidos` VARCHAR(160) NOT NULL,  
	`avatar` VARBINARY(255) NULL,  
	`sed_id` int,
	`activo` TINYINT(1) NOT NULL, 
	PRIMARY KEY  (`id`),    
  FOREIGN KEY (`grupo_id`) REFERENCES grupo(id),
UNIQUE  (`usuario`)
) ENGINE = InnoDB COMMENT = 'Usuarios del Sistema';