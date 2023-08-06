
CREATE TABLE `dofa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `debilidades` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `fortalezas` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `oportunidades` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `amenazas` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `idvisita` int(11) NOT NULL,
  ADD PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


