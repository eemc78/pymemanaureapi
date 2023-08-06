
CREATE TABLE `archivovisitas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombrearchivo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `tipoarchivo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `rutaarchivo` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `archivo` blob NOT NULL,
  `fecha` date NOT NULL,
  `idarticulo` int(11) NOT NULL,
  `idvisita` int(11) NOT NULL,
  ADD PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



ALTER TABLE `archivovisitas`
  ADD KEY `fk_archivovisitas_articulo` (`idarticulo`),
  ADD KEY `fk_terceros_visita` (`idvisita`);


ALTER TABLE `terceros`
  ADD CONSTRAINT `fk_archivovisitas_articulo` FOREIGN KEY (`articulo`) REFERENCES `articulos` (`id`),
  ADD CONSTRAINT `fk_archivovisitas_visita` FOREIGN KEY (`idvisita`) REFERENCES `visita` (`id`);

