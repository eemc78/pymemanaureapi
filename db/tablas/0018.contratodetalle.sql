

CREATE TABLE `contratodetalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idcontrato` int(11) NOT NULL,
  `idarticulo` int(11) NOT NULL,
  `estadoarticulo` int(11) NOT NULL,
  `idgestor` int(11) DEFAULT NULL,
  `observacion` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


