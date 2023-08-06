
CREATE TABLE `contratos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idtercero` int(11) NOT NULL,
  `referencianumero` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `tipo` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `idrepresentante` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `necesitacapacitacion` int(11) NOT NULL,
  `detalle` text COLLATE utf8_unicode_ci DEFAULT NULL,
  ADD PRIMARY KEY (`id`)
) ENGINE=InnoDB ;

