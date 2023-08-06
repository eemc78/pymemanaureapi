

CREATE TABLE `visitas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fecha` date NOT NULL,
  `idtercero` int(11) NOT NULL,
  `idpersona` int(11) NOT NULL,
  `renovomatricula` int(11) NOT NULL,
  `fecharenovacion` date DEFAULT NULL,
  `direccionactual` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `telefonoactual` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
  `emailactual` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `generonuevosempleos` int(11) NOT NULL,
  `cuantosempleosformales` int(11) NOT NULL,
  `cuantosempleosinformales` int(11) NOT NULL,
  `capemprendimiento` int(11) DEFAULT NULL,
  `capcontabilidad` int(11) DEFAULT NULL,
  `capsistemas` int(11) DEFAULT NULL,
  `capmarketing` int(11) DEFAULT NULL,
  `capotros` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `idarchivo` int(11) DEFAULT NULL,
  `idestadolocativa` int(11) DEFAULT NULL,
  `descripcionlocativa` int(11) DEFAULT NULL,
  `descripcionimpacto` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `incrementoventas` int(11) DEFAULT NULL,
  `iniciotramitecc` int(11) DEFAULT NULL,
  `razonnotramitecc` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `observacionesgestor` text COLLATE utf8_unicode_ci NOT NULL,
  `observacionesmicroempresario` int(11) DEFAULT NULL,
  `idrepresentante` int(11) NOT NULL,
  `idgestor` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;

