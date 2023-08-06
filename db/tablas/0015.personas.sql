

CREATE TABLE `personas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pnombre` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `snombre` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `papellido` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `sapellido` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `idtipopersona` int(11) NOT NULL,
  `sexo` varchar(1) COLLATE utf8_unicode_ci NOT NULL,
  `edad` int(11) NOT NULL,
  `direccion` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `telefonocel` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `tipoidentificacion` varchar(2) COLLATE utf8_unicode_ci NOT NULL,
  `noidentificacion` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `ciudad` varchar(5) COLLATE utf8_unicode_ci NOT NULL,
  `usuario` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `clave` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



