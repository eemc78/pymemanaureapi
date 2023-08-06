
CREATE TABLE `terceros` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `NIT` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `razonsocial` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `registradoencc` int(11) NOT NULL,
  `matriculaencc` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `fechaconstitucion` date DEFAULT NULL,
  `tipocontribuyente` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `ciudad` varchar(5) COLLATE utf8_unicode_ci NOT NULL DEFAULT '44560',
  `telefonocel` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `direccion` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `telefonofijo` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `idrepresentante` int(11) NOT NULL,
  `idsector` int(11) NOT NULL,
  `cantidadempleosformales` int(11) NOT NULL,
  `cantidadempleosinformales` int(11) NOT NULL,
  `idclasepersona` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;

