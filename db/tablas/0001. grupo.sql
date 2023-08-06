CREATE TABLE IF NOT EXISTS `grupo` ( 
    `id` BIGINT(30) UNSIGNED NOT NULL AUTO_INCREMENT ,  
    `nombre` VARCHAR(160) NOT NULL ,  
    `activo` TINYINT(1) NOT NULL ,    
PRIMARY KEY  (`id`)
) ENGINE = InnoDB COMMENT = 'Grupos de usuarios';



INSERT INTO `grupo` (`id`, `nombre`, `activo`) VALUES
(1, 'Administrador', 1),
(3, 'Gestor', 1),
(4, 'Empresa', 1);

--
-- AUTO_INCREMENT de la tabla `grupo`
--
ALTER TABLE `grupo`
  MODIFY `id` bigint(30) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;