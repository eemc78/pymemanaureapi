
CREATE TABLE `segimientoarticulos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idcontrato` int(11) NOT NULL,
  `idarticulo` int(11) NOT NULL,
  `idvisita` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `idestado` int(11) NOT NULL,
  `observaciones` text COLLATE utf8_unicode_ci NOT NULL,
  ADD PRIMARY KEY (`id`)
) ENGINE=InnoDB ;

