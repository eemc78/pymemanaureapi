-- 0001.grupo
CREATE TABLE IF NOT EXISTS `grupo` ( 
    `id` BIGINT(30) UNSIGNED NOT NULL AUTO_INCREMENT ,  
    `nombre` VARCHAR(160) NOT NULL ,  
    `activo` TINYINT(1) NOT NULL ,    
PRIMARY KEY  (`id`)) ENGINE = InnoDB COMMENT = 'Grupos de usuarios';

--
INSERT INTO `grupo` (`id`, `nombre`, `activo`) VALUES (NULL, 'Administrador', '1');

INSERT INTO `grupo` (`id`, `nombre`, `activo`) VALUES
(3, 'Gestor', 1),
(4, 'Empresa', 1);

ALTER TABLE `grupo`
  MODIFY `id` bigint(30) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;


-- 0002.emp
CREATE TABLE IF NOT EXISTS emp (
	id			int not null auto_increment,
  razonsocial	varchar(256) not null,
  nit			varchar(20) not null,
  dv 			smallint not null,
  activa		TINYINT(1) NOT NULL default 0, 
  primary key(id),
  unique(razonsocial,nit,dv)
) ENGINE=InnoDB COMMENT = 'Empresas';

--
INSERT INTO `emp` (`id`, `razonsocial`, `nit`, `dv`, `activa`) VALUES (NULL, 'Unica', '123456789', '1', '1');

-- 0003.sed
CREATE TABLE IF NOT EXISTS sed (
	id			int not null auto_increment,
  denominacion varchar(256) not null,
  activa		TINYINT(1) NOT NULL default 0, 
  emp_id		INT NOT NULL,
  primary key(id),
  FOREIGN KEY (`emp_id`) REFERENCES emp(id),
  unique(denominacion,emp_id)
) ENGINE=InnoDB COMMENT = 'Sedes';

--
INSERT INTO `sed` (`id`, `denominacion`, `activa`, `emp_id`) VALUES (NULL, 'Unica', '1', '1');

-- 0004.usu
CREATE TABLE IF NOT EXISTS  `usu` ( 
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
  FOREIGN KEY (`sed_id`) REFERENCES sed(id),
UNIQUE  (`usuario`)) ENGINE = InnoDB COMMENT = 'Usuarios del Sistema';

-- Clave: admin
INSERT INTO `usu` (`id`, `grupo_id`, `usuario`, `clave`, `nombres`, `apellidos`, `avatar`, `sed_id`, `activo`) VALUES (NULL, '1', 'admin', '21232f297a57a5a743894a0e4a801fc3', 'Administrador', '.', NULL, '1', '1');

-- 0005.api
CREATE TABLE IF NOT EXISTS  api ( 
	`id` BIGINT(30) UNSIGNED NOT NULL AUTO_INCREMENT , 
	`text_json` JSON DEFAULT NULL, 
	`sql_command` TEXT DEFAULT NULL ,
	`fecha` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
	`usuario_id` BIGINT(30) UNSIGNED NOT NULL , 
	PRIMARY KEY (`id`), 
INDEX (`usuario_id`)) ENGINE = InnoDB COMMENT = 'Peticiones a la Api'; 

--
DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_api`(IN `paramsJson` JSON)
BEGIN
   	SET @vUsuario = JSON_VALUE(paramsJson,'$.usu');
    INSERT INTO api (text_json, fecha, usuario_id) VALUES(paramsJson, now(), @vUsuario);
    SELECT LAST_INSERT_ID() id;
END$$
DELIMITER ;

--
DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_grupo`(IN js_id int)
BEGIN
  SET @metodo = '';
  SET @metodo = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json, '$.parametros') from api where id=js_id);
  if @metodo = 'nuevo_registro' then
	SET @usuario_id = (select usuario_id from api where id=js_id);
    set @nombre := JSON_VALUE(@parametros,'$.nombre');
    set @activo := JSON_VALUE(@parametros,'$.activo');
    insert into grupo (nombre,activo)
    select @nombre,@activo
    where not exists(select 1 from grupo where nombre=@nombre);
  end if;
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    if exists(select 1 from usu where grupo_id=@id) then
      select false as elimininar;
    else
      select true as eliminar;
	  end if;
  end if;
  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    delete from grupo where id=@id
    and id not in (select coalesce(grupo_id,-1) from usu);
  end if;
  if @metodo = 'editar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    set @nombre := JSON_VALUE(@parametros,'$.nombre');
    set @activo := JSON_VALUE(@parametros,'$.activo');
    update grupo set nombre=@nombre, activo=@activo
    where id=@id;
  end if;
END $$
DELIMITER ;

--
DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_emp`(IN js_id int)
BEGIN
	SET @metodo = '';
	SET @metodo = (SELECT JSON_UNQUOTE(JSON_EXTRACT(text_json,'$.metodo')) FROM api WHERE id=js_id);
	SET @parametros = (SELECT JSON_UNQUOTE(JSON_EXTRACT(text_json,'$.parametros')) from api where id=js_id);
	set @usuario_id = (select usuario_id from api where id=js_id);
	if @metodo = 'nuevo_registro' then
		set @razonsocial = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.razonsocial'));
		set @nit = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.nit'));
		set @dv = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.dv'));
		set @activa = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.activa'));
		insert into emp (razonsocial,activa,nit,dv)
		select @razonsocial,@activa,@nit,@dv
		where not exists(select 1 from emp where razonsocial=@razonsocial and nit=@nit and dv=@dv);
	end if;
	if @metodo = 'permiso_eliminar' then
		set @id = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
		if exists(select 1 from sed where emp_id=@id) then
			select false as elimininar;
		else
			select true as eliminar;
		end if;
	end if;
	if @metodo = 'eliminar_registro' then
		set @id = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
		delete from emp 
        where id=@id and id not in (select coalesce(emp_id,-1) from sed);
	end if;
    if @metodo = 'editar_registro' then
		set @id = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
		set @razonsocial = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.razonsocial'));
		set @nit = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.nit'));
		set @dv = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.dv'));
		set @activa = JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.activa'));
		update emp set razonsocial=@razonsocial, activa=@activa, nit=@nit, dv=@dv
		where id=@id;
	end if;
END $$
DELIMITER ;

--
DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_sed`(IN js_id int)
BEGIN
  SET @metodo = '';
  SET @metodo = (SELECT JSON_UNQUOTE(JSON_EXTRACT(text_json,'$.metodo')) FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_UNQUOTE(JSON_EXTRACT(text_json,'$.parametros')) from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id);
  if @metodo = 'nuevo_registro' then
	set @denominacion := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.denominacion'));
    set @activa := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.activa'));
    set @emp_id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.emp_id'));
    set @csecundario := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.csecundario'));
    set @cprimario := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cprimario'));
    
    insert into sed (denominacion,activa,emp_id,colorp,colors)
    select @denominacion,@activa,@emp_id,@cprimario,@csecundario
    where not exists(select 1 from sed where denominacion=@denominacion and id=@id);
  end if;
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    if exists(select 1 from usu where sed_id=@id) then
      select false as elimininar;
    else
      select true as eliminar;
	end if;
  end if;
  if @metodo = 'eliminar_registro' then
    set @id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    delete from sed where id=@id
    and id not in (select coalesce(sed_id,-1) from usu);
  end if;
  if @metodo = 'editar_registro' then
    set @id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @denominacion := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.denominacion'));
    set @activa := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.activa'));
    set @emp_id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.emp_id'));
    set @csecundario := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.csecundario'));
    set @cprimario := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cprimario'));
    update sed set denominacion=@denominacion, activa=@activa, emp_id=@emp_id
				   ,colorp=@cprimario, colors=@csecundario
    where id=@id;
  end if;
  if @metodo = 'consultar' then
	select id, denominacion, activa, emp_id, colorp, colors from sed where activa = 1;
  end if;
  if @metodo = 'consultar_usuario' then
  set @usu_id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.usu_id'));
	select sed.id, denominacion, activa, emp_id, colorp, colors 
    from sed
    inner join sedxusu on sedxusu.sed_id = sed.id -- select sed_id, usu_id from sedxusu;
    where sedxusu.usu_id = @usu_id and activa = 1;
  end if;
END $$
DELIMITER ;

-- 0006.estados
CREATE TABLE IF NOT EXISTS  `estados` (
  `id` int(11) NOT NULL,
  `estado` varchar(30)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  ;


INSERT INTO `estados` (`id`, `estado`) VALUES
(1, 'BUENO'),
(2, 'REGULAR'),
(3, 'MALO'),
(4, 'DADO DE BAJA'),
(10, 'ACTIVO'),
(11, 'INACTIVO'),
(20, 'NO'),
(21, 'SI'),
(23, 'NO RESPONDE');


-- 0007.tipoarticulo
CREATE TABLE IF NOT EXISTS  `tipoarticulo` (
  `id` int(11) NOT NULL AUTO_INCREMENT ,
  `tipoarticulo` varchar(40)  NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB ;


INSERT INTO `tipoarticulo` (`id`, `tipoarticulo`) VALUES
(1, 'MAQUINARIA Y EQUPOS LIVIANO'),
(2, 'HERRAMIENTAS, MENAJES Y UTENCILIOS'),
(3, 'ELECTRODOMESTICOS'),
(4, 'MUEBLES Y ENSERES'),
(5, 'EQUIPOS DE COMPUTO Y COMUNICACIONES'),
(6, 'ASESORIAS Y CAPACITACIONES');


-- 0008.tipoidentificacion
CREATE TABLE IF NOT EXISTS  `tipoidentificacion` (
  `id` varchar(2)  NOT NULL,
  `tipoidentificacion` varchar(40)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


INSERT INTO `tipoidentificacion` (`id`, `tipoidentificacion`) VALUES
('AS', 'ADULTO SIN IDENTIFICACION'),
('CC', 'CEDULA DE CIUDADANIA'),
('CD', 'CARNET DIPLOMATICO'),
('CE', 'CEDULA DE EXTRANJERIA'),
('CN', 'CERTIFICADO DE NACIDO VIVO'),
('MS', 'MENOR SIN IDENTIFICACION'),
('NI', 'NIT'),
('NU', 'NUMERO UNICO'),
('PA', 'PASAPORTE'),
('PE', 'PERMISO ESPECIAL DE PERMANENCIA'),
('PT', 'PERMISO POR PROTECCION TEMPORAL'),
('RC', 'REGISTRO CIVIL'),
('SC', 'SALVACONDUCTO DE PERMANENCIA'),
('TI', 'TARJETA DE IDENTIDAD'),
('ZZ', 'SIN IDENTIFICAR POR BDUA');


-- 0009.tipopersona
CREATE TABLE IF NOT EXISTS  `tipopersona` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipopersona` varchar(40)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


INSERT INTO `tipopersona` (`id`, `tipopersona`) VALUES
(1, 'admin'),
(2, 'Gestor'),
(3, 'Beneficiario'),
(4, 'Veedor');


-- 0010.departamentos
CREATE TABLE IF NOT EXISTS  `departamentos` (
  `id` varchar(2)  NOT NULL,
  `departamento` varchar(100)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


INSERT INTO `departamentos` (`id`, `departamento`) VALUES
('00', 'NO APLICA'),
('05', 'ANTIOQUIA'),
('08', 'ATLÁNTICO'),
('11', 'BOGOTÁ, D.C.'),
('13', 'BOLÍVAR'),
('15', 'BOYACÁ'),
('17', 'CALDAS'),
('18', 'CAQUETÁ'),
('19', 'CAUCA'),
('20', 'CESAR'),
('23', 'CÓRDOBA'),
('25', 'CUNDINAMARCA'),
('27', 'CHOCÓ'),
('41', 'HUILA'),
('44', 'LA GUAJIRA'),
('47', 'MAGDALENA'),
('50', 'META'),
('52', 'NARIÑO'),
('54', 'NORTE DE SANTANDER'),
('63', 'QUINDIO'),
('66', 'RISARALDA'),
('68', 'SANTANDER'),
('70', 'SUCRE'),
('73', 'TOLIMA'),
('76', 'VALLE DEL CAUCA'),
('81', 'ARAUCA'),
('85', 'CASANARE'),
('86', 'PUTUMAYO'),
('88', 'ARCHIPIÉLAGO DE SAN ANDRÉS, PROVIDENCIA Y SANTA CATALINA'),
('91', 'AMAZONAS'),
('94', 'GUAINÍA'),
('95', 'GUAVIARE'),
('97', 'VAUPÉS'),
('99', 'VICHADA');

--

-- 0011.clasepersona
CREATE TABLE IF NOT EXISTS  `clasepersona` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `clasepersona` varchar(20)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


INSERT INTO `clasepersona` (`id`, `clasepersona`) VALUES
(1, 'NATURAL'),
(2, 'JURIDICA');


--

-- 0012.ciudades
CREATE TABLE IF NOT EXISTS  `ciudades` (
  `id` varchar(5)  NOT NULL,
  `ciudad` varchar(30)  NOT NULL,
  `iddepartamento` varchar(2)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


INSERT INTO `ciudades` (`id`, `ciudad`, `iddepartamento`) VALUES
('05001', 'MEDELLÍN', '05'),
('05002', 'ABEJORRAL', '05'),
('05004', 'ABRIAQUÍ', '05'),
('05021', 'ALEJANDRÍA', '05'),
('05030', 'AMAGÁ', '05'),
('05031', 'AMALFI', '05'),
('05034', 'ANDES', '05'),
('05036', 'ANGELÓPOLIS', '05'),
('05038', 'ANGOSTURA', '05'),
('05040', 'ANORÍ', '05'),
('05042', 'SANTA FÉ DE ANTIOQUIA', '05'),
('05044', 'ANZÁ', '05'),
('05045', 'APARTADÓ', '05'),
('05051', 'ARBOLETES', '05'),
('05055', 'ARGELIA', '05'),
('05059', 'ARMENIA', '05'),
('05079', 'BARBOSA', '05'),
('05086', 'BELMIRA', '05'),
('05088', 'BELLO', '05'),
('05091', 'BETANIA', '05'),
('05093', 'BETULIA', '05'),
('05101', 'CIUDAD BOLÍVAR', '05'),
('05107', 'BRICEÑO', '05'),
('05113', 'BURITICÁ', '05'),
('05120', 'CÁCERES', '05'),
('05125', 'CAICEDO', '05'),
('05129', 'CALDAS', '05'),
('05134', 'CAMPAMENTO', '05'),
('05138', 'CAÑASGORDAS', '05'),
('05142', 'CARACOLÍ', '05'),
('05145', 'CARAMANTA', '05'),
('05147', 'CAREPA', '05'),
('05148', 'EL CARMEN DE VIBORAL', '05'),
('05150', 'CAROLINA', '05'),
('05154', 'CAUCASIA', '05'),
('05172', 'CHIGORODÓ', '05'),
('05190', 'CISNEROS', '05'),
('05197', 'COCORNÁ', '05'),
('05206', 'CONCEPCIÓN', '05'),
('05209', 'CONCORDIA', '05'),
('05212', 'COPACABANA', '05'),
('05234', 'DABEIBA', '05'),
('05237', 'DONMATÍAS', '05'),
('05240', 'EBÉJICO', '05'),
('05250', 'EL BAGRE', '05'),
('05264', 'ENTRERRÍOS', '05'),
('05266', 'ENVIGADO', '05'),
('05282', 'FREDONIA', '05'),
('05284', 'FRONTINO', '05'),
('05306', 'GIRALDO', '05'),
('05308', 'GIRARDOTA', '05'),
('05310', 'GÓMEZ PLATA', '05'),
('05313', 'GRANADA', '05'),
('05315', 'GUADALUPE', '05'),
('05318', 'GUARNE', '05'),
('05321', 'GUATAPÉ', '05'),
('05347', 'HELICONIA', '05'),
('05353', 'HISPANIA', '05'),
('05360', 'ITAGÜÍ', '05'),
('05361', 'ITUANGO', '05'),
('05364', 'JARDÍN', '05'),
('05368', 'JERICÓ', '05'),
('05376', 'LA CEJA', '05'),
('05380', 'LA ESTRELLA', '05'),
('05390', 'LA PINTADA', '05'),
('05400', 'LA UNIÓN', '05'),
('05411', 'LIBORINA', '05'),
('05425', 'MACEO', '05'),
('05440', 'MARINILLA', '05'),
('05467', 'MONTEBELLO', '05'),
('05475', 'MURINDÓ', '05'),
('05480', 'MUTATÁ', '05'),
('05483', 'NARIÑO', '05'),
('05490', 'NECOCLÍ', '05'),
('05495', 'NECHÍ', '05'),
('05501', 'OLAYA', '05'),
('05541', 'PEÑOL', '05'),
('05543', 'PEQUE', '05'),
('05576', 'PUEBLORRICO', '05'),
('05579', 'PUERTO BERRÍO', '05'),
('05585', 'PUERTO NARE', '05'),
('05591', 'PUERTO TRIUNFO', '05'),
('05604', 'REMEDIOS', '05'),
('05607', 'RETIRO', '05'),
('05615', 'RIONEGRO', '05'),
('05628', 'SABANALARGA', '05'),
('05631', 'SABANETA', '05'),
('05642', 'SALGAR', '05'),
('05647', 'SAN ANDRÉS DE CUERQUÍA', '05'),
('05649', 'SAN CARLOS', '05'),
('05652', 'SAN FRANCISCO', '05'),
('05656', 'SAN JERÓNIMO', '05'),
('05658', 'SAN JOSÉ DE LA MONTAÑA', '05'),
('05659', 'SAN JUAN DE URABÁ', '05'),
('05660', 'SAN LUIS', '05'),
('05664', 'SAN PEDRO DE LOS MILAGROS', '05'),
('05665', 'SAN PEDRO DE URABÁ', '05'),
('05667', 'SAN RAFAEL', '05'),
('05670', 'SAN ROQUE', '05'),
('05674', 'SAN VICENTE FERRER', '05'),
('05679', 'SANTA BÁRBARA', '05'),
('05686', 'SANTA ROSA DE OSOS', '05'),
('05690', 'SANTO DOMINGO', '05'),
('05697', 'EL SANTUARIO', '05'),
('05736', 'SEGOVIA', '05'),
('05756', 'SONSÓN', '05'),
('05761', 'SOPETRÁN', '05'),
('05789', 'TÁMESIS', '05'),
('05790', 'TARAZÁ', '05'),
('05792', 'TARSO', '05'),
('05809', 'TITIRIBÍ', '05'),
('05819', 'TOLEDO', '05'),
('05837', 'TURBO', '05'),
('05842', 'URAMITA', '05'),
('05847', 'URRAO', '05'),
('05854', 'VALDIVIA', '05'),
('05856', 'VALPARAÍSO', '05'),
('05858', 'VEGACHÍ', '05'),
('05861', 'VENECIA', '05'),
('05873', 'VIGÍA DEL FUERTE', '05'),
('05885', 'YALÍ', '05'),
('05887', 'YARUMAL', '05'),
('05890', 'YOLOMBÓ', '05'),
('05893', 'YONDÓ', '05'),
('05895', 'ZARAGOZA', '05'),
('08001', 'BARRANQUILLA', '08'),
('08078', 'BARANOA', '08'),
('08137', 'CAMPO DE LA CRUZ', '08'),
('08141', 'CANDELARIA', '08'),
('08296', 'GALAPA', '08'),
('08372', 'JUAN DE ACOSTA', '08'),
('08421', 'LURUACO', '08'),
('08433', 'MALAMBO', '08'),
('08436', 'MANATÍ', '08'),
('08520', 'PALMAR DE VARELA', '08'),
('08549', 'PIOJÓ', '08'),
('08558', 'POLONUEVO', '08'),
('08560', 'PONEDERA', '08'),
('08573', 'PUERTO COLOMBIA', '08'),
('08606', 'REPELÓN', '08'),
('08634', 'SABANAGRANDE', '08'),
('08638', 'SABANALARGA', '08'),
('08675', 'SANTA LUCÍA', '08'),
('08685', 'SANTO TOMÁS', '08'),
('08758', 'SOLEDAD', '08'),
('08770', 'SUAN', '08'),
('08832', 'TUBARÁ', '08'),
('08849', 'USIACURÍ', '08'),
('11001', 'BOGOTÁ, D.C.', '11'),
('13001', 'CARTAGENA DE INDIAS', '13'),
('13006', 'ACHÍ', '13'),
('13030', 'ALTOS DEL ROSARIO', '13'),
('13042', 'ARENAL', '13'),
('13052', 'ARJONA', '13'),
('13062', 'ARROYOHONDO', '13'),
('13074', 'BARRANCO DE LOBA', '13'),
('13140', 'CALAMAR', '13'),
('13160', 'CANTAGALLO', '13'),
('13188', 'CICUCO', '13'),
('13212', 'CÓRDOBA', '13'),
('13222', 'CLEMENCIA', '13'),
('13244', 'EL CARMEN DE BOLÍVAR', '13'),
('13248', 'EL GUAMO', '13'),
('13268', 'EL PEÑÓN', '13'),
('13300', 'HATILLO DE LOBA', '13'),
('13430', 'MAGANGUÉ', '13'),
('13433', 'MAHATES', '13'),
('13440', 'MARGARITA', '13'),
('13442', 'MARÍA LA BAJA', '13'),
('13458', 'MONTECRISTO', '13'),
('13468', 'MOMPÓS', '13'),
('13473', 'MORALES', '13'),
('13490', 'NOROSÍ', '13'),
('13549', 'PINILLOS', '13'),
('13580', 'REGIDOR', '13'),
('13600', 'RÍO VIEJO', '13'),
('13620', 'SAN CRISTÓBAL', '13'),
('13647', 'SAN ESTANISLAO', '13'),
('13650', 'SAN FERNANDO', '13'),
('13654', 'SAN JACINTO', '13'),
('13655', 'SAN JACINTO DEL CAUCA', '13'),
('13657', 'SAN JUAN NEPOMUCENO', '13'),
('13667', 'SAN MARTÍN DE LOBA', '13'),
('13670', 'SAN PABLO', '13'),
('13673', 'SANTA CATALINA', '13'),
('13683', 'SANTA ROSA', '13'),
('13688', 'SANTA ROSA DEL SUR', '13'),
('13744', 'SIMITÍ', '13'),
('13760', 'SOPLAVIENTO', '13'),
('13780', 'TALAIGUA NUEVO', '13'),
('13810', 'TIQUISIO', '13'),
('13836', 'TURBACO', '13'),
('13838', 'TURBANÁ', '13'),
('13873', 'VILLANUEVA', '13'),
('13894', 'ZAMBRANO', '13'),
('15001', 'TUNJA', '15'),
('15022', 'ALMEIDA', '15'),
('15047', 'AQUITANIA', '15'),
('15051', 'ARCABUCO', '15'),
('15087', 'BELÉN', '15'),
('15090', 'BERBEO', '15'),
('15092', 'BETÉITIVA', '15'),
('15097', 'BOAVITA', '15'),
('15104', 'BOYACÁ', '15'),
('15106', 'BRICEÑO', '15'),
('15109', 'BUENAVISTA', '15'),
('15114', 'BUSBANZÁ', '15'),
('15131', 'CALDAS', '15'),
('15135', 'CAMPOHERMOSO', '15'),
('15162', 'CERINZA', '15'),
('15172', 'CHINAVITA', '15'),
('15176', 'CHIQUINQUIRÁ', '15'),
('15180', 'CHISCAS', '15'),
('15183', 'CHITA', '15'),
('15185', 'CHITARAQUE', '15'),
('15187', 'CHIVATÁ', '15'),
('15189', 'CIÉNEGA', '15'),
('15204', 'CÓMBITA', '15'),
('15212', 'COPER', '15'),
('15215', 'CORRALES', '15'),
('15218', 'COVARACHÍA', '15'),
('15223', 'CUBARÁ', '15'),
('15224', 'CUCAITA', '15'),
('15226', 'CUÍTIVA', '15'),
('15232', 'CHÍQUIZA', '15'),
('15236', 'CHIVOR', '15'),
('15238', 'DUITAMA', '15'),
('15244', 'EL COCUY', '15'),
('15248', 'EL ESPINO', '15'),
('15272', 'FIRAVITOBA', '15'),
('15276', 'FLORESTA', '15'),
('15293', 'GACHANTIVÁ', '15'),
('15296', 'GÁMEZA', '15'),
('15299', 'GARAGOA', '15'),
('15317', 'GUACAMAYAS', '15'),
('15322', 'GUATEQUE', '15'),
('15325', 'GUAYATÁ', '15'),
('15332', 'GÜICÁN DE LA SIERRA', '15'),
('15362', 'IZA', '15'),
('15367', 'JENESANO', '15'),
('15368', 'JERICÓ', '15'),
('15377', 'LABRANZAGRANDE', '15'),
('15380', 'LA CAPILLA', '15'),
('15401', 'LA VICTORIA', '15'),
('15403', 'LA UVITA', '15'),
('15407', 'VILLA DE LEYVA', '15'),
('15425', 'MACANAL', '15'),
('15442', 'MARIPÍ', '15'),
('15455', 'MIRAFLORES', '15'),
('15464', 'MONGUA', '15'),
('15466', 'MONGUÍ', '15'),
('15469', 'MONIQUIRÁ', '15'),
('15476', 'MOTAVITA', '15'),
('15480', 'MUZO', '15'),
('15491', 'NOBSA', '15'),
('15494', 'NUEVO COLÓN', '15'),
('15500', 'OICATÁ', '15'),
('15507', 'OTANCHE', '15'),
('15511', 'PACHAVITA', '15'),
('15514', 'PÁEZ', '15'),
('15516', 'PAIPA', '15'),
('15518', 'PAJARITO', '15'),
('15522', 'PANQUEBA', '15'),
('15531', 'PAUNA', '15'),
('15533', 'PAYA', '15'),
('15537', 'PAZ DE RÍO', '15'),
('15542', 'PESCA', '15'),
('15550', 'PISBA', '15'),
('15572', 'PUERTO BOYACÁ', '15'),
('15580', 'QUÍPAMA', '15'),
('15599', 'RAMIRIQUÍ', '15'),
('15600', 'RÁQUIRA', '15'),
('15621', 'RONDÓN', '15'),
('15632', 'SABOYÁ', '15'),
('15638', 'SÁCHICA', '15'),
('15646', 'SAMACÁ', '15'),
('15660', 'SAN EDUARDO', '15'),
('15664', 'SAN JOSÉ DE PARE', '15'),
('15667', 'SAN LUIS DE GACENO', '15'),
('15673', 'SAN MATEO', '15'),
('15676', 'SAN MIGUEL DE SEMA', '15'),
('15681', 'SAN PABLO DE BORBUR', '15'),
('15686', 'SANTANA', '15'),
('15690', 'SANTA MARÍA', '15'),
('15693', 'SANTA ROSA DE VITERBO', '15'),
('15696', 'SANTA SOFÍA', '15'),
('15720', 'SATIVANORTE', '15'),
('15723', 'SATIVASUR', '15'),
('15740', 'SIACHOQUE', '15'),
('15753', 'SOATÁ', '15'),
('15755', 'SOCOTÁ', '15'),
('15757', 'SOCHA', '15'),
('15759', 'SOGAMOSO', '15'),
('15761', 'SOMONDOCO', '15'),
('15762', 'SORA', '15'),
('15763', 'SOTAQUIRÁ', '15'),
('15764', 'SORACÁ', '15'),
('15774', 'SUSACÓN', '15'),
('15776', 'SUTAMARCHÁN', '15'),
('15778', 'SUTATENZA', '15'),
('15790', 'TASCO', '15'),
('15798', 'TENZA', '15'),
('15804', 'TIBANÁ', '15'),
('15806', 'TIBASOSA', '15'),
('15808', 'TINJACÁ', '15'),
('15810', 'TIPACOQUE', '15'),
('15814', 'TOCA', '15'),
('15816', 'TOGÜÍ', '15'),
('15820', 'TÓPAGA', '15'),
('15822', 'TOTA', '15'),
('15832', 'TUNUNGUÁ', '15'),
('15835', 'TURMEQUÉ', '15'),
('15837', 'TUTA', '15'),
('15839', 'TUTAZÁ', '15'),
('15842', 'ÚMBITA', '15'),
('15861', 'VENTAQUEMADA', '15'),
('15879', 'VIRACACHÁ', '15'),
('15897', 'ZETAQUIRA', '15'),
('17001', 'MANIZALES', '17'),
('17013', 'AGUADAS', '17'),
('17042', 'ANSERMA', '17'),
('17050', 'ARANZAZU', '17'),
('17088', 'BELALCÁZAR', '17'),
('17174', 'CHINCHINÁ', '17'),
('17272', 'FILADELFIA', '17'),
('17380', 'LA DORADA', '17'),
('17388', 'LA MERCED', '17'),
('17433', 'MANZANARES', '17'),
('17442', 'MARMATO', '17'),
('17444', 'MARQUETALIA', '17'),
('17446', 'MARULANDA', '17'),
('17486', 'NEIRA', '17'),
('17495', 'NORCASIA', '17'),
('17513', 'PÁCORA', '17'),
('17524', 'PALESTINA', '17'),
('17541', 'PENSILVANIA', '17'),
('17614', 'RIOSUCIO', '17'),
('17616', 'RISARALDA', '17'),
('17653', 'SALAMINA', '17'),
('17662', 'SAMANÁ', '17'),
('17665', 'SAN JOSÉ', '17'),
('17777', 'SUPÍA', '17'),
('17867', 'VICTORIA', '17'),
('17873', 'VILLAMARÍA', '17'),
('17877', 'VITERBO', '17'),
('18001', 'FLORENCIA', '18'),
('18029', 'ALBANIA', '18'),
('18094', 'BELÉN DE LOS ANDAQUÍES', '18'),
('18150', 'CARTAGENA DEL CHAIRÁ', '18'),
('18205', 'CURILLO', '18'),
('18247', 'EL DONCELLO', '18'),
('18256', 'EL PAUJÍL', '18'),
('18410', 'LA MONTAÑITA', '18'),
('18460', 'MILÁN', '18'),
('18479', 'MORELIA', '18'),
('18592', 'PUERTO RICO', '18'),
('18610', 'SAN JOSÉ DEL FRAGUA', '18'),
('18753', 'SAN VICENTE DEL CAGUÁN', '18'),
('18756', 'SOLANO', '18'),
('18785', 'SOLITA', '18'),
('18860', 'VALPARAÍSO', '18'),
('19001', 'POPAYÁN', '19'),
('19022', 'ALMAGUER', '19'),
('19050', 'ARGELIA', '19'),
('19075', 'BALBOA', '19'),
('19100', 'BOLÍVAR', '19'),
('19110', 'BUENOS AIRES', '19'),
('19130', 'CAJIBÍO', '19'),
('19137', 'CALDONO', '19'),
('19142', 'CALOTO', '19'),
('19212', 'CORINTO', '19'),
('19256', 'EL TAMBO', '19'),
('19290', 'FLORENCIA', '19'),
('19300', 'GUACHENÉ', '19'),
('19318', 'GUAPÍ', '19'),
('19355', 'INZÁ', '19'),
('19364', 'JAMBALÓ', '19'),
('19392', 'LA SIERRA', '19'),
('19397', 'LA VEGA', '19'),
('19418', 'LÓPEZ DE MICAY', '19'),
('19450', 'MERCADERES', '19'),
('19455', 'MIRANDA', '19'),
('19473', 'MORALES', '19'),
('19513', 'PADILLA', '19'),
('19517', 'PÁEZ', '19'),
('19532', 'PATÍA', '19'),
('19533', 'PIAMONTE', '19'),
('19548', 'PIENDAMÓ - TUNÍA', '19'),
('19573', 'PUERTO TEJADA', '19'),
('19585', 'PURACÉ', '19'),
('19622', 'ROSAS', '19'),
('19693', 'SAN SEBASTIÁN', '19'),
('19698', 'SANTANDER DE QUILICHAO', '19'),
('19701', 'SANTA ROSA', '19'),
('19743', 'SILVIA', '19'),
('19760', 'SOTARA', '19'),
('19780', 'SUÁREZ', '19'),
('19785', 'SUCRE', '19'),
('19807', 'TIMBÍO', '19'),
('19809', 'TIMBIQUÍ', '19'),
('19821', 'TORIBÍO', '19'),
('19824', 'TOTORÓ', '19'),
('19845', 'VILLA RICA', '19'),
('20001', 'VALLEDUPAR', '20'),
('20011', 'AGUACHICA', '20'),
('20013', 'AGUSTÍN CODAZZI', '20'),
('20032', 'ASTREA', '20'),
('20045', 'BECERRIL', '20'),
('20060', 'BOSCONIA', '20'),
('20175', 'CHIMICHAGUA', '20'),
('20178', 'CHIRIGUANÁ', '20'),
('20228', 'CURUMANÍ', '20'),
('20238', 'EL COPEY', '20'),
('20250', 'EL PASO', '20'),
('20295', 'GAMARRA', '20'),
('20310', 'GONZÁLEZ', '20'),
('20383', 'LA GLORIA', '20'),
('20400', 'LA JAGUA DE IBIRICO', '20'),
('20443', 'MANAURE BALCÓN DEL CESAR', '20'),
('20517', 'PAILITAS', '20'),
('20550', 'PELAYA', '20'),
('20570', 'PUEBLO BELLO', '20'),
('20614', 'RÍO DE ORO', '20'),
('20621', 'LA PAZ', '20'),
('20710', 'SAN ALBERTO', '20'),
('20750', 'SAN DIEGO', '20'),
('20770', 'SAN MARTÍN', '20'),
('20787', 'TAMALAMEQUE', '20'),
('23001', 'MONTERÍA', '23'),
('23068', 'AYAPEL', '23'),
('23079', 'BUENAVISTA', '23'),
('23090', 'CANALETE', '23'),
('23162', 'CERETÉ', '23'),
('23168', 'CHIMÁ', '23'),
('23182', 'CHINÚ', '23'),
('23189', 'CIÉNAGA DE ORO', '23'),
('23300', 'COTORRA', '23'),
('23350', 'LA APARTADA', '23'),
('23417', 'LORICA', '23'),
('23419', 'LOS CÓRDOBAS', '23'),
('23464', 'MOMIL', '23'),
('23466', 'MONTELÍBANO', '23'),
('23500', 'MOÑITOS', '23'),
('23555', 'PLANETA RICA', '23'),
('23570', 'PUEBLO NUEVO', '23'),
('23574', 'PUERTO ESCONDIDO', '23'),
('23580', 'PUERTO LIBERTADOR', '23'),
('23586', 'PURÍSIMA DE LA CONCEPCIÓN', '23'),
('23660', 'SAHAGÚN', '23'),
('23670', 'SAN ANDRÉS DE SOTAVENTO', '23'),
('23672', 'SAN ANTERO', '23'),
('23675', 'SAN BERNARDO DEL VIENTO', '23'),
('23678', 'SAN CARLOS', '23'),
('23682', 'SAN JOSÉ DE URÉ', '23'),
('23686', 'SAN PELAYO', '23'),
('23807', 'TIERRALTA', '23'),
('23815', 'TUCHÍN', '23'),
('23855', 'VALENCIA', '23'),
('25001', 'AGUA DE DIOS', '25'),
('25019', 'ALBÁN', '25'),
('25035', 'ANAPOIMA', '25'),
('25040', 'ANOLAIMA', '25'),
('25053', 'ARBELÁEZ', '25'),
('25086', 'BELTRÁN', '25'),
('25095', 'BITUIMA', '25'),
('25099', 'BOJACÁ', '25'),
('25120', 'CABRERA', '25'),
('25123', 'CACHIPAY', '25'),
('25126', 'CAJICÁ', '25'),
('25148', 'CAPARRAPÍ', '25'),
('25151', 'CÁQUEZA', '25'),
('25154', 'CARMEN DE CARUPA', '25'),
('25168', 'CHAGUANÍ', '25'),
('25175', 'CHÍA', '25'),
('25178', 'CHIPAQUE', '25'),
('25181', 'CHOACHÍ', '25'),
('25183', 'CHOCONTÁ', '25'),
('25200', 'COGUA', '25'),
('25214', 'COTA', '25'),
('25224', 'CUCUNUBÁ', '25'),
('25245', 'EL COLEGIO', '25'),
('25258', 'EL PEÑÓN', '25'),
('25260', 'EL ROSAL', '25'),
('25269', 'FACATATIVÁ', '25'),
('25279', 'FÓMEQUE', '25'),
('25281', 'FOSCA', '25'),
('25286', 'FUNZA', '25'),
('25288', 'FÚQUENE', '25'),
('25290', 'FUSAGASUGÁ', '25'),
('25293', 'GACHALÁ', '25'),
('25295', 'GACHANCIPÁ', '25'),
('25297', 'GACHETÁ', '25'),
('25299', 'GAMA', '25'),
('25307', 'GIRARDOT', '25'),
('25312', 'GRANADA', '25'),
('25317', 'GUACHETÁ', '25'),
('25320', 'GUADUAS', '25'),
('25322', 'GUASCA', '25'),
('25324', 'GUATAQUÍ', '25'),
('25326', 'GUATAVITA', '25'),
('25328', 'GUAYABAL DE SÍQUIMA', '25'),
('25335', 'GUAYABETAL', '25'),
('25339', 'GUTIÉRREZ', '25'),
('25368', 'JERUSALÉN', '25'),
('25372', 'JUNÍN', '25'),
('25377', 'LA CALERA', '25'),
('25386', 'LA MESA', '25'),
('25394', 'LA PALMA', '25'),
('25398', 'LA PEÑA', '25'),
('25402', 'LA VEGA', '25'),
('25407', 'LENGUAZAQUE', '25'),
('25426', 'MACHETÁ', '25'),
('25430', 'MADRID', '25'),
('25436', 'MANTA', '25'),
('25438', 'MEDINA', '25'),
('25473', 'MOSQUERA', '25'),
('25483', 'NARIÑO', '25'),
('25486', 'NEMOCÓN', '25'),
('25488', 'NILO', '25'),
('25489', 'NIMAIMA', '25'),
('25491', 'NOCAIMA', '25'),
('25506', 'VENECIA', '25'),
('25513', 'PACHO', '25'),
('25518', 'PAIME', '25'),
('25524', 'PANDI', '25'),
('25530', 'PARATEBUENO', '25'),
('25535', 'PASCA', '25'),
('25572', 'PUERTO SALGAR', '25'),
('25580', 'PULÍ', '25'),
('25592', 'QUEBRADANEGRA', '25'),
('25594', 'QUETAME', '25'),
('25596', 'QUIPILE', '25'),
('25599', 'APULO', '25'),
('25612', 'RICAURTE', '25'),
('25645', 'SAN ANTONIO DEL TEQUENDAMA', '25'),
('25649', 'SAN BERNARDO', '25'),
('25653', 'SAN CAYETANO', '25'),
('25658', 'SAN FRANCISCO', '25'),
('25662', 'SAN JUAN DE RIOSECO', '25'),
('25718', 'SASAIMA', '25'),
('25736', 'SESQUILÉ', '25'),
('25740', 'SIBATÉ', '25'),
('25743', 'SILVANIA', '25'),
('25745', 'SIMIJACA', '25'),
('25754', 'SOACHA', '25'),
('25758', 'SOPÓ', '25'),
('25769', 'SUBACHOQUE', '25'),
('25772', 'SUESCA', '25'),
('25777', 'SUPATÁ', '25'),
('25779', 'SUSA', '25'),
('25781', 'SUTATAUSA', '25'),
('25785', 'TABIO', '25'),
('25793', 'TAUSA', '25'),
('25797', 'TENA', '25'),
('25799', 'TENJO', '25'),
('25805', 'TIBACUY', '25'),
('25807', 'TIBIRITA', '25'),
('25815', 'TOCAIMA', '25'),
('25817', 'TOCANCIPÁ', '25'),
('25823', 'TOPAIPÍ', '25'),
('25839', 'UBALÁ', '25'),
('25841', 'UBAQUE', '25'),
('25843', 'VILLA DE SAN DIEGO DE UBATÉ', '25'),
('25845', 'UNE', '25'),
('25851', 'ÚTICA', '25'),
('25862', 'VERGARA', '25'),
('25867', 'VIANÍ', '25'),
('25871', 'VILLAGÓMEZ', '25'),
('25873', 'VILLAPINZÓN', '25'),
('25875', 'VILLETA', '25'),
('25878', 'VIOTÁ', '25'),
('25885', 'YACOPÍ', '25'),
('25898', 'ZIPACÓN', '25'),
('25899', 'ZIPAQUIRÁ', '25'),
('27001', 'QUIBDÓ', '27'),
('27006', 'ACANDÍ', '27'),
('27025', 'ALTO BAUDÓ', '27'),
('27050', 'ATRATO', '27'),
('27073', 'BAGADÓ', '27'),
('27075', 'BAHÍA SOLANO', '27'),
('27077', 'BAJO BAUDÓ', '27'),
('27086', 'Belén De Bajira', '27'),
('27099', 'BOJAYÁ', '27'),
('27135', 'EL CANTÓN DEL SAN PABLO', '27'),
('27150', 'CARMEN DEL DARIÉN', '27'),
('27160', 'CÉRTEGUI', '27'),
('27205', 'CONDOTO', '27'),
('27245', 'EL CARMEN DE ATRATO', '27'),
('27250', 'EL LITORAL DEL SAN JUAN', '27'),
('27361', 'ISTMINA', '27'),
('27372', 'JURADÓ', '27'),
('27413', 'LLORÓ', '27'),
('27425', 'MEDIO ATRATO', '27'),
('27430', 'MEDIO BAUDÓ', '27'),
('27450', 'MEDIO SAN JUAN', '27'),
('27491', 'NÓVITA', '27'),
('27495', 'NUQUÍ', '27'),
('27580', 'RÍO IRÓ', '27'),
('27600', 'RÍO QUITO', '27'),
('27615', 'RIOSUCIO', '27'),
('27660', 'SAN JOSÉ DEL PALMAR', '27'),
('27745', 'SIPÍ', '27'),
('27787', 'TADÓ', '27'),
('27800', 'UNGUÍA', '27'),
('27810', 'UNIÓN PANAMERICANA', '27'),
('41001', 'NEIVA', '41'),
('41006', 'ACEVEDO', '41'),
('41013', 'AGRADO', '41'),
('41016', 'AIPE', '41'),
('41020', 'ALGECIRAS', '41'),
('41026', 'ALTAMIRA', '41'),
('41078', 'BARAYA', '41'),
('41132', 'CAMPOALEGRE', '41'),
('41206', 'COLOMBIA', '41'),
('41244', 'ELÍAS', '41'),
('41298', 'GARZÓN', '41'),
('41306', 'GIGANTE', '41'),
('41319', 'GUADALUPE', '41'),
('41349', 'HOBO', '41'),
('41357', 'ÍQUIRA', '41'),
('41359', 'ISNOS', '41'),
('41378', 'LA ARGENTINA', '41'),
('41396', 'LA PLATA', '41'),
('41483', 'NÁTAGA', '41'),
('41503', 'OPORAPA', '41'),
('41518', 'PAICOL', '41'),
('41524', 'PALERMO', '41'),
('41530', 'PALESTINA', '41'),
('41548', 'PITAL', '41'),
('41551', 'PITALITO', '41'),
('41615', 'RIVERA', '41'),
('41660', 'SALADOBLANCO', '41'),
('41668', 'SAN AGUSTÍN', '41'),
('41676', 'SANTA MARÍA', '41'),
('41770', 'SUAZA', '41'),
('41791', 'TARQUI', '41'),
('41797', 'TESALIA', '41'),
('41799', 'TELLO', '41'),
('41801', 'TERUEL', '41'),
('41807', 'TIMANÁ', '41'),
('41872', 'VILLAVIEJA', '41'),
('41885', 'YAGUARÁ', '41'),
('44001', 'RIOHACHA', '44'),
('44035', 'ALBANIA', '44'),
('44078', 'BARRANCAS', '44'),
('44090', 'DIBULLA', '44'),
('44098', 'DISTRACCIÓN', '44'),
('44110', 'EL MOLINO', '44'),
('44279', 'FONSECA', '44'),
('44378', 'HATONUEVO', '44'),
('44420', 'LA JAGUA DEL PILAR', '44'),
('44430', 'MAICAO', '44'),
('44560', 'MANAURE', '44'),
('44650', 'SAN JUAN DEL CESAR', '44'),
('44847', 'URIBIA', '44'),
('44855', 'URUMITA', '44'),
('44874', 'VILLANUEVA', '44'),
('47001', 'SANTA MARTA', '47'),
('47030', 'ALGARROBO', '47'),
('47053', 'ARACATACA', '47'),
('47058', 'ARIGUANÍ', '47'),
('47161', 'CERRO DE SAN ANTONIO', '47'),
('47170', 'CHIVOLO', '47'),
('47189', 'CIÉNAGA', '47'),
('47205', 'CONCORDIA', '47'),
('47245', 'EL BANCO', '47'),
('47258', 'EL PIÑÓN', '47'),
('47268', 'EL RETÉN', '47'),
('47288', 'FUNDACIÓN', '47'),
('47318', 'GUAMAL', '47'),
('47460', 'NUEVA GRANADA', '47'),
('47541', 'PEDRAZA', '47'),
('47545', 'PIJIÑO DEL CARMEN', '47'),
('47551', 'PIVIJAY', '47'),
('47555', 'PLATO', '47'),
('47570', 'PUEBLOVIEJO', '47'),
('47605', 'REMOLINO', '47'),
('47660', 'SABANAS DE SAN ÁNGEL', '47'),
('47675', 'SALAMINA', '47'),
('47692', 'SAN SEBASTIÁN DE BUENAVISTA', '47'),
('47703', 'SAN ZENÓN', '47'),
('47707', 'SANTA ANA', '47'),
('47720', 'SANTA BÁRBARA DE PINTO', '47'),
('47745', 'SITIONUEVO', '47'),
('47798', 'TENERIFE', '47'),
('47960', 'ZAPAYÁN', '47'),
('47980', 'ZONA BANANERA', '47'),
('50001', 'VILLAVICENCIO', '50'),
('50006', 'ACACÍAS', '50'),
('50110', 'BARRANCA DE UPÍA', '50'),
('50124', 'CABUYARO', '50'),
('50150', 'CASTILLA LA NUEVA', '50'),
('50223', 'CUBARRAL', '50'),
('50226', 'CUMARAL', '50'),
('50245', 'EL CALVARIO', '50'),
('50251', 'EL CASTILLO', '50'),
('50270', 'EL DORADO', '50'),
('50287', 'FUENTE DE ORO', '50'),
('50313', 'GRANADA', '50'),
('50318', 'GUAMAL', '50'),
('50325', 'MAPIRIPÁN', '50'),
('50330', 'MESETAS', '50'),
('50350', 'LA MACARENA', '50'),
('50370', 'URIBE', '50'),
('50400', 'LEJANÍAS', '50'),
('50450', 'PUERTO CONCORDIA', '50'),
('50568', 'PUERTO GAITÁN', '50'),
('50573', 'PUERTO LÓPEZ', '50'),
('50577', 'PUERTO LLERAS', '50'),
('50590', 'PUERTO RICO', '50'),
('50606', 'RESTREPO', '50'),
('50680', 'SAN CARLOS DE GUAROA', '50'),
('50683', 'SAN JUAN DE ARAMA', '50'),
('50686', 'SAN JUANITO', '50'),
('50689', 'SAN MARTÍN', '50'),
('50711', 'VISTAHERMOSA', '50'),
('52001', 'PASTO', '52'),
('52019', 'ALBÁN', '52'),
('52022', 'ALDANA', '52'),
('52036', 'ANCUYÁ', '52'),
('52051', 'ARBOLEDA', '52'),
('52079', 'BARBACOAS', '52'),
('52083', 'BELÉN', '52'),
('52110', 'BUESACO', '52'),
('52203', 'COLÓN', '52'),
('52207', 'CONSACÁ', '52'),
('52210', 'CONTADERO', '52'),
('52215', 'CÓRDOBA', '52'),
('52224', 'CUASPÚD', '52'),
('52227', 'CUMBAL', '52'),
('52233', 'CUMBITARA', '52'),
('52240', 'CHACHAGÜÍ', '52'),
('52250', 'EL CHARCO', '52'),
('52254', 'EL PEÑOL', '52'),
('52256', 'EL ROSARIO', '52'),
('52258', 'EL TABLÓN DE GÓMEZ', '52'),
('52260', 'EL TAMBO', '52'),
('52287', 'FUNES', '52'),
('52317', 'GUACHUCAL', '52'),
('52320', 'GUAITARILLA', '52'),
('52323', 'GUALMATÁN', '52'),
('52352', 'ILES', '52'),
('52354', 'IMUÉS', '52'),
('52356', 'IPIALES', '52'),
('52378', 'LA CRUZ', '52'),
('52381', 'LA FLORIDA', '52'),
('52385', 'LA LLANADA', '52'),
('52390', 'LA TOLA', '52'),
('52399', 'LA UNIÓN', '52'),
('52405', 'LEIVA', '52'),
('52411', 'LINARES', '52'),
('52418', 'LOS ANDES', '52'),
('52427', 'MAGÜÍ', '52'),
('52435', 'MALLAMA', '52'),
('52473', 'MOSQUERA', '52'),
('52480', 'NARIÑO', '52'),
('52490', 'OLAYA HERRERA', '52'),
('52506', 'OSPINA', '52'),
('52520', 'FRANCISCO PIZARRO', '52'),
('52540', 'POLICARPA', '52'),
('52560', 'POTOSÍ', '52'),
('52565', 'PROVIDENCIA', '52'),
('52573', 'PUERRES', '52'),
('52585', 'PUPIALES', '52'),
('52612', 'RICAURTE', '52'),
('52621', 'ROBERTO PAYÁN', '52'),
('52678', 'SAMANIEGO', '52'),
('52683', 'SANDONÁ', '52'),
('52685', 'SAN BERNARDO', '52'),
('52687', 'SAN LORENZO', '52'),
('52693', 'SAN PABLO', '52'),
('52694', 'SAN PEDRO DE CARTAGO', '52'),
('52696', 'SANTA BÁRBARA', '52'),
('52699', 'SANTACRUZ', '52'),
('52720', 'SAPUYES', '52'),
('52786', 'TAMINANGO', '52'),
('52788', 'TANGUA', '52'),
('52835', 'SAN ANDRÉS DE TUMACO', '52'),
('52838', 'TÚQUERRES', '52'),
('52885', 'YACUANQUER', '52'),
('54001', 'SAN JOSÉ DE CÚCUTA', '54'),
('54003', 'ÁBREGO', '54'),
('54051', 'ARBOLEDAS', '54'),
('54099', 'BOCHALEMA', '54'),
('54109', 'BUCARASICA', '54'),
('54125', 'CÁCOTA', '54'),
('54128', 'CÁCHIRA', '54'),
('54172', 'CHINÁCOTA', '54'),
('54174', 'CHITAGÁ', '54'),
('54206', 'CONVENCIÓN', '54'),
('54223', 'CUCUTILLA', '54'),
('54239', 'DURANIA', '54'),
('54245', 'EL CARMEN', '54'),
('54250', 'EL TARRA', '54'),
('54261', 'EL ZULIA', '54'),
('54313', 'GRAMALOTE', '54'),
('54344', 'HACARÍ', '54'),
('54347', 'HERRÁN', '54'),
('54377', 'LABATECA', '54'),
('54385', 'LA ESPERANZA', '54'),
('54398', 'LA PLAYA', '54'),
('54405', 'LOS PATIOS', '54'),
('54418', 'LOURDES', '54'),
('54480', 'MUTISCUA', '54'),
('54498', 'OCAÑA', '54'),
('54518', 'PAMPLONA', '54'),
('54520', 'PAMPLONITA', '54'),
('54553', 'PUERTO SANTANDER', '54'),
('54599', 'RAGONVALIA', '54'),
('54660', 'SALAZAR', '54'),
('54670', 'SAN CALIXTO', '54'),
('54673', 'SAN CAYETANO', '54'),
('54680', 'SANTIAGO', '54'),
('54720', 'SARDINATA', '54'),
('54743', 'SILOS', '54'),
('54800', 'TEORAMA', '54'),
('54810', 'TIBÚ', '54'),
('54820', 'TOLEDO', '54'),
('54871', 'VILLA CARO', '54'),
('54874', 'VILLA DEL ROSARIO', '54'),
('63001', 'ARMENIA', '63'),
('63111', 'BUENAVISTA', '63'),
('63130', 'CALARCÁ', '63'),
('63190', 'CIRCASIA', '63'),
('63212', 'CÓRDOBA', '63'),
('63272', 'FILANDIA', '63'),
('63302', 'GÉNOVA', '63'),
('63401', 'LA TEBAIDA', '63'),
('63470', 'MONTENEGRO', '63'),
('63548', 'PIJAO', '63'),
('63594', 'QUIMBAYA', '63'),
('63690', 'SALENTO', '63'),
('66001', 'PEREIRA', '66'),
('66045', 'APÍA', '66'),
('66075', 'BALBOA', '66'),
('66088', 'BELÉN DE UMBRÍA', '66'),
('66170', 'DOSQUEBRADAS', '66'),
('66318', 'GUÁTICA', '66'),
('66383', 'LA CELIA', '66'),
('66400', 'LA VIRGINIA', '66'),
('66440', 'MARSELLA', '66'),
('66456', 'MISTRATÓ', '66'),
('66572', 'PUEBLO RICO', '66'),
('66594', 'QUINCHÍA', '66'),
('66682', 'SANTA ROSA DE CABAL', '66'),
('66687', 'SANTUARIO', '66'),
('68001', 'BUCARAMANGA', '68'),
('68013', 'AGUADA', '68'),
('68020', 'ALBANIA', '68'),
('68051', 'ARATOCA', '68'),
('68077', 'BARBOSA', '68'),
('68079', 'BARICHARA', '68'),
('68081', 'BARRANCABERMEJA', '68'),
('68092', 'BETULIA', '68'),
('68101', 'BOLÍVAR', '68'),
('68121', 'CABRERA', '68'),
('68132', 'CALIFORNIA', '68'),
('68147', 'CAPITANEJO', '68'),
('68152', 'CARCASÍ', '68'),
('68160', 'CEPITÁ', '68'),
('68162', 'CERRITO', '68'),
('68167', 'CHARALÁ', '68'),
('68169', 'CHARTA', '68'),
('68176', 'CHIMA', '68'),
('68179', 'CHIPATÁ', '68'),
('68190', 'CIMITARRA', '68'),
('68207', 'CONCEPCIÓN', '68'),
('68209', 'CONFINES', '68'),
('68211', 'CONTRATACIÓN', '68'),
('68217', 'COROMORO', '68'),
('68229', 'CURITÍ', '68'),
('68235', 'EL CARMEN DE CHUCURÍ', '68'),
('68245', 'EL GUACAMAYO', '68'),
('68250', 'EL PEÑÓN', '68'),
('68255', 'EL PLAYÓN', '68'),
('68264', 'ENCINO', '68'),
('68266', 'ENCISO', '68'),
('68271', 'FLORIÁN', '68'),
('68276', 'FLORIDABLANCA', '68'),
('68296', 'GALÁN', '68'),
('68298', 'GÁMBITA', '68'),
('68307', 'GIRÓN', '68'),
('68318', 'GUACA', '68'),
('68320', 'GUADALUPE', '68'),
('68322', 'GUAPOTÁ', '68'),
('68324', 'GUAVATÁ', '68'),
('68327', 'GÜEPSA', '68'),
('68344', 'HATO', '68'),
('68368', 'JESÚS MARÍA', '68'),
('68370', 'JORDÁN', '68'),
('68377', 'LA BELLEZA', '68'),
('68385', 'LANDÁZURI', '68'),
('68397', 'LA PAZ', '68'),
('68406', 'LEBRIJA', '68'),
('68418', 'LOS SANTOS', '68'),
('68425', 'MACARAVITA', '68'),
('68432', 'MÁLAGA', '68'),
('68444', 'MATANZA', '68'),
('68464', 'MOGOTES', '68'),
('68468', 'MOLAGAVITA', '68'),
('68498', 'OCAMONTE', '68'),
('68500', 'OIBA', '68'),
('68502', 'ONZAGA', '68'),
('68522', 'PALMAR', '68'),
('68524', 'PALMAS DEL SOCORRO', '68'),
('68533', 'PÁRAMO', '68'),
('68547', 'PIEDECUESTA', '68'),
('68549', 'PINCHOTE', '68'),
('68572', 'PUENTE NACIONAL', '68'),
('68573', 'PUERTO PARRA', '68'),
('68575', 'PUERTO WILCHES', '68'),
('68615', 'RIONEGRO', '68'),
('68655', 'SABANA DE TORRES', '68'),
('68669', 'SAN ANDRÉS', '68'),
('68673', 'SAN BENITO', '68'),
('68679', 'SAN GIL', '68'),
('68682', 'SAN JOAQUÍN', '68'),
('68684', 'SAN JOSÉ DE MIRANDA', '68'),
('68686', 'SAN MIGUEL', '68'),
('68689', 'SAN VICENTE DE CHUCURÍ', '68'),
('68705', 'SANTA BÁRBARA', '68'),
('68720', 'SANTA HELENA DEL OPÓN', '68'),
('68745', 'SIMACOTA', '68'),
('68755', 'SOCORRO', '68'),
('68770', 'SUAITA', '68'),
('68773', 'SUCRE', '68'),
('68780', 'SURATÁ', '68'),
('68820', 'TONA', '68'),
('68855', 'VALLE DE SAN JOSÉ', '68'),
('68861', 'VÉLEZ', '68'),
('68867', 'VETAS', '68'),
('68872', 'VILLANUEVA', '68'),
('68895', 'ZAPATOCA', '68'),
('70001', 'SINCELEJO', '70'),
('70110', 'BUENAVISTA', '70'),
('70124', 'CAIMITO', '70'),
('70204', 'COLOSÓ', '70'),
('70215', 'COROZAL', '70'),
('70221', 'COVEÑAS', '70'),
('70230', 'CHALÁN', '70'),
('70233', 'EL ROBLE', '70'),
('70235', 'GALERAS', '70'),
('70265', 'GUARANDA', '70'),
('70400', 'LA UNIÓN', '70'),
('70418', 'LOS PALMITOS', '70'),
('70429', 'MAJAGUAL', '70'),
('70473', 'MORROA', '70'),
('70508', 'OVEJAS', '70'),
('70523', 'PALMITO', '70'),
('70670', 'SAMPUÉS', '70'),
('70678', 'SAN BENITO ABAD', '70'),
('70702', 'SAN JUAN DE BETULIA', '70'),
('70708', 'SAN MARCOS', '70'),
('70713', 'SAN ONOFRE', '70'),
('70717', 'SAN PEDRO', '70'),
('70742', 'SAN LUIS DE SINCÉ', '70'),
('70771', 'SUCRE', '70'),
('70820', 'SANTIAGO DE TOLÚ', '70'),
('70823', 'TOLÚ VIEJO', '70'),
('73001', 'IBAGUÉ', '73'),
('73024', 'ALPUJARRA', '73'),
('73026', 'ALVARADO', '73'),
('73030', 'AMBALEMA', '73'),
('73043', 'ANZOÁTEGUI', '73'),
('73055', 'ARMERO', '73'),
('73067', 'ATACO', '73'),
('73124', 'CAJAMARCA', '73'),
('73148', 'CARMEN DE APICALÁ', '73'),
('73152', 'CASABIANCA', '73'),
('73168', 'CHAPARRAL', '73'),
('73200', 'COELLO', '73'),
('73217', 'COYAIMA', '73'),
('73226', 'CUNDAY', '73'),
('73236', 'DOLORES', '73'),
('73268', 'ESPINAL', '73'),
('73270', 'FALAN', '73'),
('73275', 'FLANDES', '73'),
('73283', 'FRESNO', '73'),
('73319', 'GUAMO', '73'),
('73347', 'HERVEO', '73'),
('73349', 'HONDA', '73'),
('73352', 'ICONONZO', '73'),
('73408', 'LÉRIDA', '73'),
('73411', 'LÍBANO', '73'),
('73443', 'SAN SEBASTIÁN DE MARIQUITA', '73'),
('73449', 'MELGAR', '73'),
('73461', 'MURILLO', '73'),
('73483', 'NATAGAIMA', '73'),
('73504', 'ORTEGA', '73'),
('73520', 'PALOCABILDO', '73'),
('73547', 'PIEDRAS', '73'),
('73555', 'PLANADAS', '73'),
('73563', 'PRADO', '73'),
('73585', 'PURIFICACIÓN', '73'),
('73616', 'RIOBLANCO', '73'),
('73622', 'RONCESVALLES', '73'),
('73624', 'ROVIRA', '73'),
('73671', 'SALDAÑA', '73'),
('73675', 'SAN ANTONIO', '73'),
('73678', 'SAN LUIS', '73'),
('73686', 'SANTA ISABEL', '73'),
('73770', 'SUÁREZ', '73'),
('73854', 'VALLE DE SAN JUAN', '73'),
('73861', 'VENADILLO', '73'),
('73870', 'VILLAHERMOSA', '73'),
('73873', 'VILLARRICA', '73'),
('76001', 'CALI', '76'),
('76020', 'ALCALÁ', '76'),
('76036', 'ANDALUCÍA', '76'),
('76041', 'ANSERMANUEVO', '76'),
('76054', 'ARGELIA', '76'),
('76100', 'BOLÍVAR', '76'),
('76109', 'BUENAVENTURA', '76'),
('76111', 'GUADALAJARA DE BUGA', '76'),
('76113', 'BUGALAGRANDE', '76'),
('76122', 'CAICEDONIA', '76'),
('76126', 'CALIMA', '76'),
('76130', 'CANDELARIA', '76'),
('76147', 'CARTAGO', '76'),
('76233', 'DAGUA', '76'),
('76243', 'EL ÁGUILA', '76'),
('76246', 'EL CAIRO', '76'),
('76248', 'EL CERRITO', '76'),
('76250', 'EL DOVIO', '76'),
('76275', 'FLORIDA', '76'),
('76306', 'GINEBRA', '76'),
('76318', 'GUACARÍ', '76'),
('76364', 'JAMUNDÍ', '76'),
('76377', 'LA CUMBRE', '76'),
('76400', 'LA UNIÓN', '76'),
('76403', 'LA VICTORIA', '76'),
('76497', 'OBANDO', '76'),
('76520', 'PALMIRA', '76'),
('76563', 'PRADERA', '76'),
('76606', 'RESTREPO', '76'),
('76616', 'RIOFRÍO', '76'),
('76622', 'ROLDANILLO', '76'),
('76670', 'SAN PEDRO', '76'),
('76736', 'SEVILLA', '76'),
('76823', 'TORO', '76'),
('76828', 'TRUJILLO', '76'),
('76834', 'TULUÁ', '76'),
('76845', 'ULLOA', '76'),
('76863', 'VERSALLES', '76'),
('76869', 'VIJES', '76'),
('76890', 'YOTOCO', '76'),
('76892', 'YUMBO', '76'),
('76895', 'ZARZAL', '76'),
('81001', 'ARAUCA', '81'),
('81065', 'ARAUQUITA', '81'),
('81220', 'CRAVO NORTE', '81'),
('81300', 'FORTUL', '81'),
('81591', 'PUERTO RONDÓN', '81'),
('81736', 'SARAVENA', '81'),
('81794', 'TAME', '81'),
('85001', 'YOPAL', '85'),
('85010', 'AGUAZUL', '85'),
('85015', 'CHÁMEZA', '85'),
('85125', 'HATO COROZAL', '85'),
('85136', 'LA SALINA', '85'),
('85139', 'MANÍ', '85'),
('85162', 'MONTERREY', '85'),
('85225', 'NUNCHÍA', '85'),
('85230', 'OROCUÉ', '85'),
('85250', 'PAZ DE ARIPORO', '85'),
('85263', 'PORE', '85'),
('85279', 'RECETOR', '85'),
('85300', 'SABANALARGA', '85'),
('85315', 'SÁCAMA', '85'),
('85325', 'SAN LUIS DE PALENQUE', '85'),
('85400', 'TÁMARA', '85'),
('85410', 'TAURAMENA', '85'),
('85430', 'TRINIDAD', '85'),
('85440', 'VILLANUEVA', '85'),
('86001', 'MOCOA', '86'),
('86219', 'COLÓN', '86'),
('86320', 'ORITO', '86'),
('86568', 'PUERTO ASÍS', '86'),
('86569', 'PUERTO CAICEDO', '86'),
('86571', 'PUERTO GUZMÁN', '86'),
('86573', 'PUERTO LEGUÍZAMO', '86'),
('86749', 'SIBUNDOY', '86'),
('86755', 'SAN FRANCISCO', '86'),
('86757', 'SAN MIGUEL', '86'),
('86760', 'SANTIAGO', '86'),
('86865', 'VALLE DEL GUAMUEZ', '86'),
('86885', 'VILLAGARZÓN', '86'),
('88001', 'SAN ANDRÉS', '88'),
('88564', 'PROVIDENCIA', '88'),
('91001', 'LETICIA', '91'),
('91263', 'EL ENCANTO', '91'),
('91405', 'LA CHORRERA', '91'),
('91407', 'LA PEDRERA', '91'),
('91430', 'LA VICTORIA', '91'),
('91460', 'MIRITÍ - PARANÁ', '91'),
('91530', 'PUERTO ALEGRÍA', '91'),
('91536', 'PUERTO ARICA', '91'),
('91540', 'PUERTO NARIÑO', '91'),
('91669', 'PUERTO SANTANDER', '91'),
('91798', 'TARAPACÁ', '91'),
('94001', 'INÍRIDA', '94'),
('94343', 'BARRANCO MINAS', '94'),
('94663', 'MAPIRIPANA', '94'),
('94883', 'SAN FELIPE', '94'),
('94884', 'PUERTO COLOMBIA', '94'),
('94885', 'LA GUADALUPE', '94'),
('94886', 'CACAHUAL', '94'),
('94887', 'PANA PANA', '94'),
('94888', 'MORICHAL', '94'),
('95001', 'SAN JOSÉ DEL GUAVIARE', '95'),
('95015', 'CALAMAR', '95'),
('95025', 'EL RETORNO', '95'),
('95200', 'MIRAFLORES', '95'),
('97001', 'MITÚ', '97'),
('97161', 'CARURÚ', '97'),
('97511', 'PACOA', '97'),
('97666', 'TARAIRA', '97'),
('97777', 'PAPUNAHUA', '97'),
('97889', 'YAVARATÉ', '97'),
('99001', 'PUERTO CARREÑO', '99'),
('99524', 'LA PRIMAVERA', '99'),
('99624', 'SANTA ROSALÍA', '99'),
('99773', 'CUMARIBO', '99');



ALTER TABLE `ciudades`
  ADD KEY `fk_ciudad_departamento` (`iddepartamento`);

ALTER TABLE `ciudades`
  ADD CONSTRAINT `fk_ciudad_departamento` FOREIGN KEY (`iddepartamento`) REFERENCES `departamentos` (`id`);

--

-- 0013.sector
CREATE TABLE IF NOT EXISTS  `sector` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



INSERT INTO `sector` (`id`, `nombre`) VALUES
(1, 'ALMACEN ROPA Y CALZADO'),
(2, 'ARTESANIAS'),
(3, 'CARPINTERIA'),
(4, 'COMERCIO PESCADOS Y MARISCOS'),
(5, 'HELADERIAS Y REFRESCOS'),
(6, 'ORGANIZACIÓN DE EVENTOS'),
(7, 'PANADERIAS'),
(8, 'PRODUCTOS LACTEOS'),
(9, 'RECREACION Y ENTRETENIMIENTO INFANTIL'),
(10, 'RESTAURANTES'),
(11, 'SALONES DE BELLEZA Y ESTETICA'),
(12, 'SERVICIO ALQUILER LAVADORAS'),
(13, 'SERVICIOS PARA AUTOS'),
(14, 'SERVICIOS TECNOLOGIA Y SOFWARE'),
(15, 'SERVICIOS TURISTICOS'),
(16, 'SERVICIOS Y ASESORIAS'),
(17, 'TIENDAS AL POR MENOR'),
(18, 'VARIEDADES Y MISCELANEOS'),
(19, 'VENTA CARNICOS');


--
-- 0014.Articulo
CREATE TABLE IF NOT EXISTS  `Articulo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(255)  NOT NULL,
  `idtipoarticulo` int(11) NOT NULL,
  `estado` varchar(20)  NOT NULL,
  `observaciones` text  DEFAULT NULL,
  `caracteristicas` text  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



INSERT INTO `Articulo` (`id`, `nombre`, `idtipoarticulo`, `estado`, `observaciones`, `caracteristicas`) VALUES
(1, 'AIRE ACONDIC 1 1/2 CABALLO', 3, '1', NULL, 'MILEXUS'),
(2, 'ANAFRES 40 CMS * 70 LARGO', 1, '1', NULL, 'GENERICO'),
(3, 'ASADOR A CARBON  EN HIERRO 80CMS  X 60CMS X 90 CMS ALTO', 1, '1', NULL, 'GENERICO'),
(4, 'ASESORIAS EN GESTION ORGANIZACIONAL, CONTABLE Y FINANCIERA', 6, '1', NULL, ''),
(5, 'BASCULA DIGITAL 40 KGS', 1, '1', NULL, 'PRIMO'),
(6, 'CABA PLASTICA 42 LITROS ', 2, '1', NULL, 'ESTRA'),
(7, 'CALDERO PARA FREIR GRANDE  #50', 2, '1', NULL, 'NACIONAL'),
(8, 'CAMA SALTARIN DE 6 TUBOS (BRINCA BRINCA) de 1.4 mts', 1, '1', NULL, 'nacional'),
(9, 'CAMAS ASOLEADORAS + MESITA AUXILIAR DE CENTRO', 1, '1', NULL, 'RIMAX'),
(10, 'CARRITO CON RUEDAS PARA SALON ORGANIZADOR 5 GAVETAS', 1, '1', NULL, 'NACIONAL'),
(11, 'CARRO  COMIDAS RAPIDAS GRANDE (1.80MTS X 80 FONDO  X 90 ALTO) (4 PUESTOS:  2 FREIDORA, PLANCHA Y VAPORIZADOR)', 1, '1', NULL, 'NACIONAL'),
(12, 'CARRO COMIDAS RAPIDAS  1,20X 60X 1,30', 1, '1', NULL, 'NACIONAL'),
(13, 'COMPRESOR DE AIRE 24LTS 2,H HP ', 1, '1', NULL, 'EINHELL'),
(14, 'COMPUTADOR DE MESA', 5, '1', NULL, 'AIO HP'),
(15, 'COMPUTADOR PORTATIL 15P CON WINDOWS 10', 5, '1', NULL, 'AIO HP'),
(16, 'CONGELADOR HORIZONTAL 150 LTS', 1, '1', NULL, 'VISIVO'),
(17, 'CONGELADOR HORIZONTAL 200 LTS', 1, '1', NULL, 'VISIVO'),
(18, 'CONGELADOR HORIZONTAL 390 LTS', 1, '1', NULL, 'VISIVO'),
(19, 'CONGELADOR REFRIGERADOR  145 LTS', 1, '1', NULL, 'MABE'),
(20, 'CONGELADOR REFRIGERADOR  HORIZONTAL 282 LTS ', 1, '1', NULL, 'INDUCOL'),
(21, 'CONGELADOR REFRIGERADOR HORIZONTAL 200 LTS', 1, '1', NULL, 'VISIVO'),
(22, 'ENFRIADOR BOTELLERO ( NEVERA TIPO VITRINA HORIZONTAL K-SCH254', 1, '1', NULL, 'KALLEY'),
(23, 'ESCRITORIO', 4, '1', NULL, ''),
(24, 'Esmeril pequeño  VOLTAJE 110V  1/2HP  6PULGADAS  3450 RPM', 1, '1', NULL, 'ELITE'),
(25, 'Espejo  (TIPO HOLIWOOD)  80CM ANCHO  X 1.95CM ALTO INCLUYENDO PATAS', 4, '1', NULL, 'NACIONAL'),
(26, 'ESPEJO GRANDES  60CMS X 80 CMS', 4, '1', NULL, 'JUST HOME'),
(27, 'ESTABILIZADOR ELEVADOR 2000W', 1, '1', NULL, 'MAGON'),
(28, 'ESTABILIZADOR REGULADOR DE VOLTAJE 2000W ', 1, '1', NULL, 'ULTRALINE'),
(29, 'ESTACION DE CALOR KATEX 852', 1, '1', NULL, ''),
(30, 'ESTACION DE TRABAJO (ESCRITORIO 72x100x40cm + SILLA EJECUTIVA)', 4, '1', NULL, 'JUST HOME'),
(31, 'ESTANTE 6 ENTREPAÑOS 75CM FRENTE X 23 DE FONDO X 2 MT ALTO, METALICO', 4, '1', NULL, 'NACIONAL'),
(32, 'ESTANTES CUATRO ENTREPAÑOS MADERA LADO A LADO MEDIDAS 1,30 ALTO X 1,20 ANCHO X 30 DE FONDO CADA ENTREPAÑOS', 4, '1', NULL, 'DIMAC'),
(33, 'ESTANTES TRES ENTREPAÑOS MADERA RH Y 12 FLAUTAS', 4, '1', NULL, 'DIMAC'),
(34, 'ESTUFA DE 2 FOGONES QUEM DOBLE  ', 3, '1', NULL, 'NACIONAL'),
(35, 'ESTUFA INDUSTRIAL 2P', 1, '1', NULL, 'NACIONAL'),
(36, 'ESTUFA INDUSTRIAL 3P', 1, '1', NULL, 'NACIONAL'),
(37, 'EXTRACTOR DE JUGO 900L', 3, '1', NULL, 'RECCO'),
(38, 'Freidora DE 2 PUESTOS A GAS EN ACERO', 1, '1', NULL, 'GENERICO'),
(39, 'Hidrolavadora a gasolina de alta presión 1800W  220PSI', 1, '1', NULL, 'TOTAL TOOLS'),
(40, 'HIDROLAVADORA DE ALTA PRESION 1800W  2200PSI', 1, '1', NULL, 'TOTAL TOOLS'),
(41, 'HORNO MEDIANO DE 2 PUERTAS MULTIFUNCIONAL DE 2 P', 1, '1', NULL, 'NACIONAL'),
(42, 'HORNO MICROHONDAS', 3, '1', NULL, 'KALLEY'),
(43, 'LAVACABEZAS', 1, '1', NULL, 'NACIONAL'),
(44, 'LAVADORAS SEMIAUTOMATICA DE 7KG ', 1, '1', NULL, 'VISIVO'),
(45, 'LICUADORA', 3, '1', NULL, 'OSTER'),
(46, 'LICUADORA CROMADA DE 700W CON VASO DE VIDRIO ', 3, '1', NULL, 'OSTER'),
(47, 'MANIQUIES CUERPO ENTERO DAMA', 4, '1', NULL, 'NACIONAL'),
(48, 'Máquina d soldar  160 AMPERIOS ', 1, '1', NULL, 'ELITE'),
(49, 'MAQUINA DE COSER', 1, '1', NULL, 'YENSI'),
(50, 'MAQUINA DE MOTILAR PROFESIONAL', 1, '1', NULL, 'WALL'),
(51, 'MAQUINA FILETEADORA 5 HILOS CON PUNTADA DE SEGURIDAD', 1, '1', NULL, 'UNION O KINGER'),
(52, 'MESA PARA CORTAR LAS TELAS de 1.80 largo x 1.20 fondo y 90 cms de alto', 4, '1', NULL, 'NACIONAL'),
(53, 'MESA PARA UÑAS ', 4, '1', NULL, ''),
(54, 'MESA PLASTICA', 4, '1', NULL, 'RIMO'),
(55, 'MESAS METALICAS REDONDA', 4, '1', NULL, 'NACIONAL'),
(56, 'MESON DE ACERO (ALTO 1.10 X 60 CMS DE ANCHO X 120 CMS LARGO)', 4, '1', NULL, 'NACIONAL'),
(57, 'MOLINO ELECTRICO PARA MAIZ CON MOTOR 1HP', 1, '1', NULL, ''),
(58, 'MotoBOMBA DE 1 CABALLO 750 W ', 1, '1', NULL, 'TOTAL TOOLS'),
(59, 'NEVERA TIPO VITRINA HORIZONTAL 254L - CONGELADOR', 1, '1', NULL, 'KALLEY'),
(60, 'OLLA CON CAPACIDAD DE 10 LTS #32', 2, '1', NULL, 'IMUSA'),
(61, 'PLANCHA PARA CABELLO  PROFESIONAL DE 480°F', 1, '1', NULL, ''),
(62, 'PLANCHA SEPARADORA KT 968 PLUS ', 1, '1', NULL, ''),
(63, 'PLANTA ELECTRICA DE 3500W 110/220V', 3, '1', NULL, 'LIFAN'),
(64, 'Repiza  1,20 ANCHO X 30 FONDO EN RH MADERA (RIEL + 3 ENTREPAÑOS)', 4, '1', NULL, 'DIMAC'),
(65, 'SANDUCHERA TIPO PANINI GRILL', 3, '1', NULL, 'JUST HOME'),
(66, 'SECADOR PROFESIONAL 3800W', 1, '1', NULL, ''),
(67, 'SILLA RECLINABLE NEUMATICA', 4, '1', NULL, 'NACIONAL'),
(68, 'SILLA EJECUTIVA', 4, '1', NULL, ''),
(69, 'SILLA METALICA', 4, '1', NULL, 'NACIONAL'),
(70, 'SILLA PLASTICA CON BRAZO', 4, '1', NULL, 'ARTIPLASTCO'),
(71, 'SILLA PLASTICA SIN BRAZOS ', 4, '1', NULL, 'ARTIPLASTCO'),
(72, 'SILLAS PLAYERAS', 4, '1', NULL, 'RIMAX'),
(73, 'VENTILADOR DE PEDESTAL 18\"', 3, '1', NULL, 'ALTEZA'),
(74, 'VITRINA EN ALUMINO 1,50 X 1 ALTO X 36 FONDO  3DIVISIONES EN VIDRIO', 4, '1', NULL, 'NACIONAL'),
(75, 'VITRINA PQ EN ALUMINIO( ANCHO 1MTS,  ALTO 1MT , 36 CMS DE FONDO)', 4, '1', NULL, 'NACIONAL');



ALTER TABLE `Articulo`
  ADD KEY `fk_articulos_tipoarticulo` (`idtipoarticulo`);


ALTER TABLE `Articulo`
  ADD CONSTRAINT `fk_articulos_tipoarticulo` FOREIGN KEY (`idtipoarticulo`) REFERENCES `tipoarticulo` (`id`);


--
-- 0015.personas

CREATE TABLE IF NOT EXISTS  `personas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pnombre` varchar(20)  NOT NULL,
  `snombre` varchar(20)  NOT NULL,
  `papellido` varchar(20)  NOT NULL,
  `sapellido` varchar(20)  NOT NULL,
  `idtipopersona` int(11) NOT NULL,
  `sexo` varchar(1)  NOT NULL,
  `edad` int(11) NOT NULL,
  `direccion` varchar(255)  NOT NULL,
  `telefonocel` varchar(16)  NOT NULL,
  `email` varchar(255)  NOT NULL,
  `tipoidentificacion` varchar(2)  NOT NULL,
  `noidentificacion` varchar(20)  NOT NULL,
  `ciudad` varchar(5)  NOT NULL,
  `usuario` varchar(20)  NOT NULL,
  `clave` varchar(255)  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



INSERT INTO `personas` (`id`, `pnombre`, `snombre`, `papellido`, `sapellido`, `idtipopersona`, `sexo`, `edad`, `direccion`, `telefonocel`, `email`, `tipoidentificacion`, `noidentificacion`, `ciudad`, `usuario`, `clave`) VALUES
(1, 'EDWIN', 'ALVEIRO', 'VELAZQUEZ', 'MENGUAL', 3, 'H', 51, 'CLL 9  #5-12', '3136952972', 'EMAIL@GMAIL.COM', 'CC', '5185135', '44560', '', ''),
(2, 'JUAN', 'JACOBO', 'PINEDO', 'MARTINEZ', 3, 'H', 59, 'CLL 6  #7 A - 37', '3115842587', 'EMAIL@GMAIL.COM', 'CC', '17867829', '44560', '', ''),
(3, 'ALICIA', '', 'MERCADO', 'PUSHAINA', 3, 'M', 67, 'CRA 2 # 5 - 36', '3045903121', 'EMAIL@GMAIL.COM', 'CC', '40837766', '44560', '', ''),
(4, 'RONALD', 'YAIMITH', 'PEÑARANDA', 'TORRES', 3, 'H', 43, 'CLLE 4 # 5 - 65', '3113747411', 'EMAIL@GMAIL.COM', 'CC', '84086125', '44560', '', ''),
(5, 'WILLIAM', 'ANDRES', 'SOSA', 'GARCIA', 3, 'H', 32, 'CLL 9 B # 9 - 23', '3108367428', 'EMAIL@GMAIL.COM', 'CC', '1047966978', '44560', '', ''),
(6, 'SHARON', 'DINELLY', 'MARTINEZ', 'REDONDO', 3, 'M', 37, 'CLL 7 # 5 - 93', '3175356504', 'EMAIL@GMAIL.COM', 'CC', '40943245', '44560', '', ''),
(7, 'JOSE', 'RAFAEL', 'ALARCON', 'MENGUAL', 3, 'H', 62, 'CLL 9 # 5 - 12', '3216051839', 'EMAIL@GMAIL.COM', 'CC', '17855598', '44560', '', ''),
(8, 'ANGELA', 'MARIA', 'ECHEVERRY', 'HIDALGO', 3, 'M', 42, 'CARRETERA SUBESTACION MANAURE KM 1 KM 1', '3114004333', 'EMAIL@GMAIL.COM', 'CC', '43381843', '44560', '', ''),
(9, 'ORLANDO', '', 'LOZANO', 'TORRES', 3, 'H', 52, 'CAR  1  # 6 - 25 ALTOS DE SALINAS', '3105089990', 'EMAIL@GMAIL.COM', 'CC', '84033287', '44560', '', ''),
(10, 'CARLOS', 'MARIO', 'BERNAL', 'BURITICA', 3, 'H', 56, 'CLL 3 # 6-06 MANAURE ABAJO', '3105428250', 'EMAIL@GMAIL.COM', 'CC', '17856644', '44560', '', ''),
(11, 'KENIN', 'ANTONIO', 'HERRERA', 'CABALLERO', 3, 'H', 38, 'CL 8 CON CARRERA 3 # 3 - 4', '3216041804', 'EMAIL@GMAIL.COM', 'CC', '84092584', '44560', '', ''),
(12, 'YELITZA', '', 'QUINTERO', 'CABALLERO', 3, 'M', 35, 'SECTOR 1 MZ C - 1', '3207312082', 'EMAIL@GMAIL.COM', 'CC', '1124359140', '44560', '', ''),
(13, 'ARINDA', '', 'URIRAYU', 'EPINAYU', 3, 'M', 51, 'CLL 9 # 8 - 156', '3044540891', 'EMAIL@GMAIL.COM', 'CC', '56069104', '44560', '', ''),
(14, 'MARYORIS', 'DE JESUS', 'FREYLE', 'URIANA', 3, 'M', 42, 'CALLE 6 # 7 A - 51', '3182797894', 'EMAIL@GMAIL.COM', 'CC', '40935722', '44560', '', ''),
(15, 'FRANCIA', 'ELENA', 'GUERRA', 'DE CABALLERO', 3, 'M', 67, 'CLL 10A  # 7 - 44', '3218770777', 'EMAIL@GMAIL.COM', 'CC', '36488583', '44560', '', ''),
(16, 'KELVIS', '', 'DE ARMAS', 'VELASQUEZ', 3, 'H', 27, 'Kra 2 # 4 - 25', '3015250046', 'EMAIL@GMAIL.COM', 'CC', '1124409040', '44560', '', ''),
(17, 'VILMA', 'CANDELARIA', 'DE LA CRUZ', 'PALMERA', 3, 'M', 30, 'Calle 6 Cra 5 - 29 Apto 1', '3156338492', 'EMAIL@GMAIL.COM', 'CC', '1081808006', '44560', '', ''),
(18, 'VIANIS', '', 'BERNAL', 'RAMOS', 3, 'M', 31, 'Calle 1 A # 7 Oeste - 16', '3163284431', 'EMAIL@GMAIL.COM', 'CC', '1124383386', '44560', '', ''),
(19, 'YESID', '', 'MONSALVE', 'MERCADO', 3, 'H', 36, 'BARRIO BERLIN CRA ', '3024126093', 'EMAIL@GMAIL.COM', 'CC', '1124365807', '44560', '', ''),
(20, 'ROBERTH', 'JUNIOR', 'ANGULO', 'SUAREZ', 3, 'H', 40, 'No Tiene', '3114090057', 'EMAIL@GMAIL.COM', 'CC', '8526678', '44560', '', ''),
(21, 'JHON', '', 'RIOS', 'LEAL', 3, 'H', 26, 'Calle 6 # 7A - 23', '3022363627', 'EMAIL@GMAIL.COM', 'CC', '1006910372', '44560', '', ''),
(22, 'KEILA', 'LINETH', 'VALBUENA', 'GUTIERREZ', 3, 'M', 27, 'Calle 1A # 4 - 32', '3002590687', 'EMAIL@GMAIL.COM', 'CC', '1124408032', '44560', '', ''),
(23, 'SOLEDAD', '', 'GONZALEZ', '', 3, 'M', 42, 'Calle 1A # 4 - 32', '3015934238', 'EMAIL@GMAIL.COM', 'CC', '56091828', '44560', '', ''),
(24, 'RAFAEL', '', 'JARAMILLO', 'MENGUAL', 3, 'H', 48, 'CRA 7# 7-05', '3205748563', 'EMAIL@GMAIL.COM', 'CC', '5185172', '44560', '', ''),
(25, 'NEIFER', 'JOSE', 'CASTELLAR', 'MEZA', 3, 'H', 27, 'KRA 3#9-78', '3013985196', 'EMAIL@GMAIL.COM', 'CC', '1124409125', '44560', '', ''),
(26, 'YERLIS', '', 'GUTIERREZ', '', 3, 'M', 24, 'VILLA SARA SECTOR 1 LOTE 3 MZ B-3', '3114546317', 'EMAIL@GMAIL.COM', 'CC', '112414422', '44560', '', ''),
(27, 'MARIA', '', 'PUSHAINA', '', 3, 'M', 29, 'CALLE 12 # BARRIO LA BENDICION DE DIOS SARCHIMANA', '3113226343', 'EMAIL@GMAIL.COM', 'CC', '1124406162', '44560', '', ''),
(28, 'IRULA', 'ROSA', 'MEZA', 'OVIEDO', 3, 'M', 51, 'CARRETERA MANAURE URIBIA KL 1-109', '3006089686', 'EMAIL@GMAIL.COM', 'CC', '64476748', '44560', '', ''),
(29, 'IMACULADA', '', 'GUARANDA', 'CHAR', 3, 'M', 50, 'VILLA SARA SECTOR 1 MZB-3 LOTE3 ', '3023966040', 'EMAIL@GMAIL.COM', 'CC', '56100327', '44560', '', ''),
(30, 'REYES', '', 'EPINAYU', '', 3, 'H', 44, 'CARRETERA MANAURE URIBIA KL 1-143', '3218818794', 'EMAIL@GMAIL.COM', 'CC', '56100290', '44560', '', ''),
(31, 'LUZMILA', '', 'POLO', 'PEÑA', 3, 'M', 50, 'Calle 11 # 1OESTE -23', '3206220556', 'EMAIL@GMAIL.COM', 'CC', '50875486', '44560', '', ''),
(32, 'CARLOS', '', 'MARICHAL', 'VEGLIANTE', 3, 'H', 33, 'Carrera 4 #8 - 5', '3003336144', 'EMAIL@GMAIL.COM', 'CC', '1045675203', '44560', '', ''),
(33, 'GLORIA', 'MARIA', 'TORRES', '', 3, 'M', 50, 'CALLE 10 CON CRA 1 OESTE  SARCHIMANA', '3206220556', 'EMAIL@GMAIL.COM', 'CC', '30664969', '44560', '', ''),
(34, 'ARANSIDA', '', 'AGUILAR', 'GONZALEZ', 3, 'M', 45, 'CALLE 4 KRA 7 #7-57', '3114095904', 'EMAIL@GMAIL.COM', 'CC', '56103501', '44560', '', ''),
(35, 'LUZ', 'MARIA', 'GUTIERREZ', 'PANA', 3, 'M', 62, 'BARRIO 10 DE MARZO CALLE13B # 13-35', '3126832130', 'EMAIL@GMAIL.COM', 'CC', '27023254', '44560', '', ''),
(36, 'MARIA', 'ELENA', 'CASTRO', '', 3, 'M', 21, 'VILLA SARA SECTOR 1 MZ G-3', '3134323004', 'EMAIL@GMAIL.COM', 'CC', '100434660', '44560', '', ''),
(37, 'JOSE', 'MIGUEL', 'IGUARAN', 'IPUANA', 3, 'H', 37, 'CALLE 5 # 5-39', '3217102885', 'EMAIL@GMAIL.COM', 'CC', '17946996', '44560', '', ''),
(38, 'LUIS', 'ALFREDO', 'BOLIVAR', '', 3, 'H', 27, 'VILLA SARA  SECTOR 1 MZ H12 ', '3207320001', 'EMAIL@GMAIL.COM', 'CC', '1124409437', '44560', '', ''),
(39, 'ILEIN', 'MILETH', 'PANA', 'CUETO', 3, 'M', 27, 'CALLE #4 MZ D barrio 10 DE MARZO', '3133921264', 'EMAIL@GMAIL.COM', 'CC', '1124408850', '44560', '', ''),
(40, 'OMAR', '', 'ARREGOCES', 'PRIETO', 3, 'H', 63, 'CALLE 7 No. 3-58', '3117810090', 'EMAIL@GMAIL.COM', 'CC', '17806729', '44560', '', ''),
(41, 'MARÍA', 'FERNÁNDEZ', 'PÁEZ', 'ARIAS', 3, 'M', 21, 'SECTOR  1 MZ I-2 VILLA SARA ', '3187612706', 'EMAIL@GMAIL.COM', 'CC', '1007971296', '44560', '', ''),
(42, 'AMAIRANITH', '', 'ROMERO', 'ROSADO', 3, 'M', 25, 'CALLE 9 # 5-47', '3046455272', 'EMAIL@GMAIL.COM', 'CC', '1192905605', '44560', '', ''),
(43, 'CARLOS', 'ANDRES', 'BERNAL', '', 3, 'H', 23, 'CALLE 3  # 8-16', '3106532232', 'EMAIL@GMAIL.COM', 'CC', '1124416095', '44560', '', ''),
(44, 'SILVIRA', '', 'PUSHAINA', 'URIANA', 3, 'M', 43, 'CALLE12 KRA 12-9', '3217284133', 'EMAIL@GMAIL.COM', 'CC', '56102768', '44560', '', ''),
(45, 'ELEMILETH', 'CABAS', 'LÓPEZ', '', 3, 'M', 24, 'Calle 14 A # 6 A MZ B Casa 8 ', '3216867486', 'EMAIL@GMAIL.COM', 'CC', '1192789873', '44560', '', ''),
(46, 'DAINER', 'RAFAEL', 'IGUARAN', 'IPUANA', 3, 'H', 29, 'CALLE 9 # 7- 136 BARRIO EL CARMEN', '3005447031', 'EMAIL@GMAIL.COM', 'CC', '1010072730', '44560', '', ''),
(47, 'MIGUEL', 'ANGEL', 'MARICHAL', 'CABALLERO', 3, 'H', 29, 'CRA 4 # 8 21', '3005447031', 'EMAIL@GMAIL.COM', 'CC', '1042461873', '44560', '', ''),
(48, 'JOSE', 'DOMINGO', 'AMAYA', 'CASTRO', 3, 'H', 50, 'CRA 9 #  CALLE 8 - 6 ESQUINA', '3216837242', 'EMAIL@GMAIL.COM', 'CC', '78756809', '44560', '', ''),
(49, 'MARTIN', 'LUIS', 'TORRES', 'TOVAR', 3, 'H', 58, 'CRA 1 # 6 - 20', '3013266103', 'EMAIL@GMAIL.COM', 'CC', '84041218', '44560', '', ''),
(50, 'MARLYS', 'ISABEL', 'JARAMILLO', 'MARTINEZ', 3, 'M', 38, 'CALLE 6  # 6 - 11', '3042501525', 'EMAIL@GMAIL.COM', 'CC', '40857989', '44560', '', ''),
(51, 'WILBER', 'FRANCISCO', 'DAZA', 'PIMIENTA', 3, 'H', 22, 'Calle 7 cra 7 - 130', '3014454090', 'EMAIL@GMAIL.COM', 'CC', '1124419529', '44560', '', '');


ALTER TABLE `personas`
  ADD KEY `fk_persona_ciudad` (`ciudad`),
  ADD KEY `fk_persona_tipoidentificacion` (`tipoidentificacion`),
  ADD KEY `fk_persona_tipopersona` (`idtipopersona`);

ALTER TABLE `personas`
  ADD CONSTRAINT `fk_persona_ciudad` FOREIGN KEY (`ciudad`) REFERENCES `ciudades` (`id`),
  ADD CONSTRAINT `fk_persona_tipoidentificacion` FOREIGN KEY (`tipoidentificacion`) REFERENCES `tipoidentificacion` (`id`),
  ADD CONSTRAINT `fk_persona_tipopersona` FOREIGN KEY (`idtipopersona`) REFERENCES `tipopersona` (`id`);


--

-- 0016.terceros
CREATE TABLE IF NOT EXISTS  `terceros` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `NIT` varchar(20)  NOT NULL,
  `razonsocial` varchar(255)  NOT NULL,
  `registradoencc` int(11) NOT NULL,
  `matriculaencc` varchar(20)  NOT NULL,
  `fechaconstitucion` date DEFAULT NULL,
  `tipocontribuyente` varchar(20)  NOT NULL,
  `ciudad` varchar(5)  NOT NULL DEFAULT '44560',
  `telefonocel` varchar(16)  NOT NULL,
  `email` varchar(255)  NOT NULL,
  `direccion` varchar(255)  NOT NULL,
  `telefonofijo` varchar(16)  NOT NULL,
  `idrepresentante` int(11) NOT NULL,
  `idsector` int(11) NOT NULL,
  `cantidadempleosformales` int(11) NOT NULL,
  `cantidadempleosinformales` int(11) NOT NULL,
  `idclasepersona` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



INSERT INTO `terceros` (`id`, `NIT`, `razonsocial`, `registradoencc`, `matriculaencc`, `fechaconstitucion`, `tipocontribuyente`, `ciudad`, `telefonocel`, `email`, `direccion`, `telefonofijo`, `idrepresentante`, `idsector`, `cantidadempleosformales`, `cantidadempleosinformales`, `idclasepersona`) VALUES
(1, '', 'ENTRETENIMIENTO NIÑOS (BRINCA BRINCA)', 0, '', NULL, '', '44560', '3136952972', 'EMAIL@ENTIDAD.COM', 'CLL 9  #5-12', '3136952972', 1, 9, 0, 0, NULL),
(2, '', 'VENTA COMIDA CAZUELAS AMBULANTES', 0, '', NULL, '', '44560', '3115842587', 'EMAIL@ENTIDAD.COM', 'CLL 6  #7 A - 37', '3115842587', 2, 10, 0, 0, NULL),
(3, '', 'DISEÑO, ELABORACION Y VENTAS DE ARTESANIAS', 0, '', NULL, '', '44560', '3045903121', 'EMAIL@ENTIDAD.COM', 'CRA 2 # 5 - 36', '3045903121', 3, 2, 0, 0, NULL),
(4, '', 'EBANISTERIA, FABRICACION MUEBLES DE MADERA', 0, '', NULL, '', '44560', '3113747411', 'EMAIL@ENTIDAD.COM', 'CLLE 4 # 5 - 65', '3113747411', 4, 3, 0, 0, NULL),
(5, '', 'VENTAS AL POR MENOR DE ARTICULOS DE LA CANASTA FAMILIAR, MISCELANOS Y VARIEDADES', 0, '', NULL, '', '44560', '3108367428', 'EMAIL@ENTIDAD.COM', 'CLL 9 B # 9 - 23', '3108367428', 5, 17, 0, 0, NULL),
(6, '', 'VENTA COMIDAS RAPIDAS', 0, '', NULL, '', '44560', '3175356504', 'EMAIL@ENTIDAD.COM', 'CLL 7 # 5 - 93', '3175356504', 6, 10, 0, 0, NULL),
(7, '', 'VENTA CHICHAS, BOLIS', 0, '', NULL, '', '44560', '3216051839', 'EMAIL@ENTIDAD.COM', 'CLL 9 # 5 - 12', '3216051839', 7, 5, 0, 0, NULL),
(8, '', 'VENTAS AL POR MENOR DE ARTICULOS DE LA CANASTA FAMILIAR, MISCELANOS Y VARIEDADES', 0, '', NULL, '', '44560', '3114004333', 'EMAIL@ENTIDAD.COM', 'CARRETERA SUBESTACION MANAURE KM 1 KM 1', '3114004333', 8, 17, 0, 0, NULL),
(9, '', 'VENTA COMIDAS RAPIDAS', 0, '', NULL, '', '44560', '3105089990', 'EMAIL@ENTIDAD.COM', 'CAR  1  # 6 - 25 ALTOS DE SALINAS', '3105089990', 9, 10, 0, 0, NULL),
(10, '', 'VENTA ENSALADAS DE LANGOSTA, MARISCOS, ', 0, '', NULL, '', '44560', '3105428250', 'EMAIL@ENTIDAD.COM', 'CLL 3 # 6-06 MANAURE ABAJO', '3105428250', 10, 10, 0, 0, NULL),
(11, '', 'ALQUILER DE SILLAS Y MESAS, MANTELES, CARPAS PARA EVENTOS', 0, '', NULL, '', '44560', '3216041804', 'EMAIL@ENTIDAD.COM', 'CL 8 CON CARRERA 3 # 3 - 4', '3216041804', 11, 6, 0, 0, NULL),
(12, '', 'VENTA DE DESAYUNOS DETALLES', 0, '', NULL, '', '44560', '3207312082', 'EMAIL@ENTIDAD.COM', 'SECTOR 1 MZ C - 1', '3207312082', 12, 18, 0, 0, NULL),
(13, '', 'VENTA COMIDAS RAPIDAS', 0, '', NULL, '', '44560', '3044540891', 'EMAIL@ENTIDAD.COM', 'CLL 9 # 8 - 156', '3044540891', 13, 10, 0, 0, NULL),
(14, '', 'VENTAS DE MARISCOS, LANGOSTA, CAMARON, CARACOL', 0, '', NULL, '', '44560', '3182797894', 'EMAIL@ENTIDAD.COM', 'CALLE 6 # 7 A - 51', '3182797894', 14, 4, 0, 0, NULL),
(15, '', 'DISEÑO, CONFECCION Y VENTA DE ARTESANIAS: MANTAS TIPICAS WAYUU', 0, '', NULL, '', '44560', '3218770777', 'EMAIL@ENTIDAD.COM', 'CLL 10A  # 7 - 44', '3218770777', 15, 2, 0, 0, NULL),
(16, '', 'COMERCIANTE', 0, '', NULL, '', '44560', '3015250046', 'EMAIL@ENTIDAD.COM', 'Kra 2 # 4 - 25', '3015250046', 16, 10, 0, 0, NULL),
(17, '', 'VENTA DE ROPA', 0, '', NULL, '', '44560', '3156338492', 'EMAIL@ENTIDAD.COM', 'Calle 6 Cra 5 - 29 Apto 1', '3156338492', 17, 1, 0, 0, NULL),
(18, '', 'VENTA DE BOLIS ', 0, '', NULL, '', '44560', '3163284431', 'EMAIL@ENTIDAD.COM', 'Calle 1 A # 7 Oeste - 16', '3163284431', 18, 5, 0, 0, NULL),
(19, '', 'LAVADERO DE AUTOS', 0, '', NULL, '', '44560', '3024126093', 'EMAIL@ENTIDAD.COM', 'BARRIO BERLIN CRA ', '3024126093', 19, 13, 0, 0, NULL),
(20, '', 'Pintor Automotriz', 0, '', NULL, '', '44560', '3114090057', 'EMAIL@ENTIDAD.COM', 'No Tiene', '3114090057', 20, 13, 0, 0, NULL),
(21, '', 'PESCADOR', 0, '', NULL, '', '44560', '3022363627', 'EMAIL@ENTIDAD.COM', 'Calle 6 # 7A - 23', '3022363627', 21, 4, 0, 0, NULL),
(22, '', 'TIENDA DE BELLEZA', 0, '', NULL, '', '44560', '3002590687', 'EMAIL@ENTIDAD.COM', 'Calle 1A # 4 - 32', '3002590687', 22, 11, 0, 0, NULL),
(23, '', 'VENTA DE FRITOS', 0, '', NULL, '', '44560', '3015934238', 'EMAIL@ENTIDAD.COM', 'Calle 1A # 4 - 32', '3015934238', 23, 10, 0, 0, NULL),
(24, '', 'VENTAS DE PESCADO ', 0, '', NULL, '', '44560', '3205748563', 'EMAIL@ENTIDAD.COM', 'CRA 7# 7-05', '3205748563', 24, 4, 0, 0, NULL),
(25, '', 'ALQUILER DE LAVADORA', 0, '', NULL, '', '44560', '3013985196', 'EMAIL@ENTIDAD.COM', 'KRA 3#9-78', '3013985196', 25, 12, 0, 0, NULL),
(26, '', 'SALA DE BELLEZA', 0, '', NULL, '', '44560', '3114546317', 'EMAIL@ENTIDAD.COM', 'VILLA SARA SECTOR 1 LOTE 3 MZ B-3', '3114546317', 26, 11, 0, 0, NULL),
(27, '', 'VENTAS DE BOLIS Y PALETAS ', 0, '', NULL, '', '44560', '3113226343', 'EMAIL@ENTIDAD.COM', 'CALLE 12 # BARRIO LA BENDICION DE DIOS SARCHIMANA', '3113226343', 27, 5, 0, 0, NULL),
(28, '', 'SALA DE BELLEZA', 0, '', NULL, '', '44560', '3006089686', 'EMAIL@ENTIDAD.COM', 'CARRETERA MANAURE URIBIA KL 1-109', '3006089686', 28, 11, 0, 0, NULL),
(29, '', 'COMERCIANTE', 0, '', NULL, '', '44560', '3023966040', 'EMAIL@ENTIDAD.COM', 'VILLA SARA SECTOR 1 MZB-3 LOTE3 ', '3023966040', 29, 18, 0, 0, NULL),
(30, '', 'ALQUILER DE LAVADORA ', 0, '', NULL, '', '44560', '3218818794', 'EMAIL@ENTIDAD.COM', 'CARRETERA MANAURE URIBIA KL 1-143', '3218818794', 30, 12, 0, 0, NULL),
(31, '', 'TIENDA', 0, '', NULL, '', '44560', '3206220556', 'EMAIL@ENTIDAD.COM', 'Calle 11 # 1OESTE -23', '3206220556', 31, 17, 0, 0, NULL),
(32, '', 'PANADERIAS', 0, '', NULL, '', '44560', '3003336144', 'EMAIL@ENTIDAD.COM', 'Carrera 4 #8 - 5', '3003336144', 32, 7, 0, 0, NULL),
(33, '', 'VENTA DE BEBIDAS ', 0, '', NULL, '', '44560', '3206220556', 'EMAIL@ENTIDAD.COM', 'CALLE 10 CON CRA 1 OESTE  SARCHIMANA', '3206220556', 33, 5, 0, 0, NULL),
(34, '', 'REFRESQUERIA ', 0, '', NULL, '', '44560', '3114095904', 'EMAIL@ENTIDAD.COM', 'CALLE 4 KRA 7 #7-57', '3114095904', 34, 5, 0, 0, NULL),
(35, '', 'VENTA DE BOLIS Y CHICHAS ', 0, '', NULL, '', '44560', '3126832130', 'EMAIL@ENTIDAD.COM', 'BARRIO 10 DE MARZO CALLE13B # 13-35', '3126832130', 35, 5, 0, 0, NULL),
(36, '', 'VARIEDADES', 0, '', NULL, '', '44560', '3134323004', 'EMAIL@ENTIDAD.COM', 'VILLA SARA SECTOR 1 MZ G-3', '3134323004', 36, 18, 0, 0, NULL),
(37, '', 'EXPENDIO DE CERDO', 0, '', NULL, '', '44560', '3217102885', 'EMAIL@ENTIDAD.COM', 'CALLE 5 # 5-39', '3217102885', 37, 19, 0, 0, NULL),
(38, '', 'VENTA DE PESCADO', 0, '', NULL, '', '44560', '3207320001', 'EMAIL@ENTIDAD.COM', 'VILLA SARA  SECTOR 1 MZ H12 ', '3207320001', 38, 4, 0, 0, NULL),
(39, '', 'VENTA DE CERDO ', 0, '', NULL, '', '44560', '3133921264', 'EMAIL@ENTIDAD.COM', 'CALLE #4 MZ D barrio 10 DE MARZO', '3133921264', 39, 19, 0, 0, NULL),
(40, '', 'SERVICIOS y ASESORIAS', 0, '', NULL, '', '44560', '3117810090', 'EMAIL@ENTIDAD.COM', 'CALLE 7 No. 3-58', '3117810090', 40, 16, 0, 0, NULL),
(41, '', ' COMIDAS RAPIDAS', 0, '', NULL, '', '44560', '3187612706', 'EMAIL@ENTIDAD.COM', 'SECTOR  1 MZ I-2 VILLA SARA ', '3187612706', 41, 10, 0, 0, NULL),
(42, '', 'TECNICO DE CELULAR', 0, '', NULL, '', '44560', '3046455272', 'EMAIL@ENTIDAD.COM', 'CALLE 9 # 5-47', '3046455272', 42, 14, 0, 0, NULL),
(43, '', 'REFRESQUERIA', 0, '', NULL, '', '44560', '3106532232', 'EMAIL@ENTIDAD.COM', 'CALLE 3  # 8-16', '3106532232', 43, 5, 0, 0, NULL),
(44, '', 'ARTESANIA', 0, '', NULL, '', '44560', '3217284133', 'EMAIL@ENTIDAD.COM', 'CALLE12 KRA 12-9', '3217284133', 44, 2, 0, 0, NULL),
(45, '', 'SALON DE BELLEZA', 0, '', NULL, '', '44560', '3216867486', 'EMAIL@ENTIDAD.COM', 'Calle 14 A # 6 A MZ B Casa 8 ', '3216867486', 45, 11, 0, 0, NULL),
(46, '', 'COMERCIANTE', 0, '', NULL, '', '44560', '3005447031', 'EMAIL@ENTIDAD.COM', 'CALLE 9 # 7- 136 BARRIO EL CARMEN', '3005447031', 46, 19, 0, 0, NULL),
(47, '', 'COMERCIANTE', 0, '', NULL, '', '44560', '3005447031', 'EMAIL@ENTIDAD.COM', 'CRA 4 # 8 21', '3005447031', 47, 1, 0, 0, NULL),
(48, '', 'VENTAS AL POR MENOR DE ARTICULOS DE LA CANASTA FAMILIAR, MISCELANOS Y VARIEDADES', 0, '', NULL, '', '44560', '3216837242', 'EMAIL@ENTIDAD.COM', 'CRA 9 #  CALLE 8 - 6 ESQUINA', '3216837242', 48, 17, 0, 0, NULL),
(49, '', 'ALQUILER SILLAS DE PLAYA, CARPAS Y VENTA DE BEBIDAS REFRESCANTES', 0, '', NULL, '', '44560', '3013266103', 'EMAIL@ENTIDAD.COM', 'CRA 1 # 6 - 20', '3013266103', 49, 15, 0, 0, NULL),
(50, '', 'VENTA DE BEBIDAS REFRESCANTES MICHELADAS CON FRUTAS', 0, '', NULL, '', '44560', '3042501525', 'EMAIL@ENTIDAD.COM', 'CALLE 6  # 6 - 11', '3042501525', 50, 5, 0, 0, NULL),
(51, '', 'YOGURES', 0, '', NULL, '', '44560', '3014454090', 'EMAIL@ENTIDAD.COM', 'Calle 7 cra 7 - 130', '3014454090', 51, 8, 0, 0, NULL);


ALTER TABLE `terceros`
  ADD KEY `fk_terceros_ciudad` (`ciudad`),
  ADD KEY `fk_terceros_clasepersona` (`idclasepersona`),
  ADD KEY `fk_terceros_personarepresentante` (`idrepresentante`),
  ADD KEY `fk_terceros_sector` (`idsector`);


ALTER TABLE `terceros`
  ADD CONSTRAINT `fk_terceros_ciudad` FOREIGN KEY (`ciudad`) REFERENCES `ciudades` (`id`),
  ADD CONSTRAINT `fk_terceros_clasepersona` FOREIGN KEY (`idclasepersona`) REFERENCES `clasepersona` (`id`),
  ADD CONSTRAINT `fk_terceros_personarepresentante` FOREIGN KEY (`idrepresentante`) REFERENCES `personas` (`id`),
  ADD CONSTRAINT `fk_terceros_sector` FOREIGN KEY (`idsector`) REFERENCES `sector` (`id`);

--

-- 0017.contratos
CREATE TABLE IF NOT EXISTS  `contratos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idtercero` int(11) NOT NULL,
  `referencianumero` varchar(20)  DEFAULT NULL,
  `fecha` date DEFAULT NULL,
  `tipo` varchar(20)  DEFAULT NULL,
  `idrepresentante` varchar(20)  NOT NULL,
  `necesitacapacitacion` int(11) NOT NULL,
  `detalle` text  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


INSERT INTO `contratos` (`id`, `idtercero`, `referencianumero`, `fecha`, `tipo`, `idrepresentante`, `necesitacapacitacion`, `detalle`) VALUES
(1, 1, '001', NULL, NULL, '1', 1, 'Entrega de bienes o servicios a EDWIN ALVEIRO VELAZQUEZ MENGUAL dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(2, 2, '002', NULL, NULL, '1', 2, 'Entrega de bienes o servicios a JUAN JACOBO PINEDO MARTINEZ dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(3, 3, '003', NULL, NULL, '1', 3, 'Entrega de bienes o servicios a ALICIA MERCADO PUSHAINA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(4, 4, '004', NULL, NULL, '1', 4, 'Entrega de bienes o servicios a RONALD YAIMITH PEÑARANDA TORRES dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(5, 5, '005', NULL, NULL, '1', 5, 'Entrega de bienes o servicios a WILLIAM ANDRES SOSA GARCIA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(6, 6, '006', NULL, NULL, '1', 6, 'Entrega de bienes o servicios a SHARON DINELLY MARTINEZ REDONDO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(7, 7, '007', NULL, NULL, '1', 7, 'Entrega de bienes o servicios a JOSE RAFAEL ALARCON MENGUAL dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(8, 8, '008', NULL, NULL, '1', 8, 'Entrega de bienes o servicios a ANGELA MARIA ECHEVERRY HIDALGO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(9, 9, '009', NULL, NULL, '1', 9, 'Entrega de bienes o servicios a ORLANDO LOZANO TORRES dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(10, 10, '010', NULL, NULL, '1', 10, 'Entrega de bienes o servicios a CARLOS MARIO BERNAL BURITICA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(11, 11, '011', NULL, NULL, '1', 11, 'Entrega de bienes o servicios a KENIN ANTONIO HERRERA CABALLERO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(12, 12, '012', NULL, NULL, '1', 12, 'Entrega de bienes o servicios a YELITZA QUINTERO CABALLERO  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(13, 13, '013', NULL, NULL, '1', 13, 'Entrega de bienes o servicios a ARINDA URIRAYU EPINAYU dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(14, 14, '014', NULL, NULL, '1', 14, 'Entrega de bienes o servicios a MARYORIS DE JESUS  FREYLE URIANA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(15, 15, '015', NULL, NULL, '1', 15, 'Entrega de bienes o servicios a FRANCIA ELENA GUERRA DE CABALLERO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(16, 16, '016', NULL, NULL, '1', 16, 'Entrega de bienes o servicios a KELVIS DE ARMAS VELASQUEZ dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(17, 17, '017', NULL, NULL, '1', 17, 'Entrega de bienes o servicios a VILMA CANDELARIA DE LA CRUZ PALMERA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(18, 18, '018', NULL, NULL, '1', 18, 'Entrega de bienes o servicios a VIANIS BERNAL RAMOS  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(19, 19, '019', NULL, NULL, '1', 19, 'Entrega de bienes o servicios a YESID MONSALVE MERCADO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(20, 20, '020', NULL, NULL, '1', 20, 'Entrega de bienes o servicios a ROBERTH JUNIOR ANGULO SUAREZ dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(21, 21, '021', NULL, NULL, '1', 21, 'Entrega de bienes o servicios a JHON RIOS LEAL dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(22, 22, '022', NULL, NULL, '1', 22, 'Entrega de bienes o servicios a KEILA LINETH VALBUENA GUTIERREZ  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(23, 23, '023', NULL, NULL, '1', 23, 'Entrega de bienes o servicios a SOLEDAD GONZALEZ  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(24, 24, '024', NULL, NULL, '1', 24, 'Entrega de bienes o servicios a RAFAEL JARAMILLO  MENGUAL  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(25, 25, '025', NULL, NULL, '1', 25, 'Entrega de bienes o servicios a NEIFER JOSE CASTELLAR MEZA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(26, 26, '026', NULL, NULL, '1', 26, 'Entrega de bienes o servicios a YERLIS  GUTIERREZ dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(27, 27, '027', NULL, NULL, '1', 27, 'Entrega de bienes o servicios a MARIA PUSHAINA  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(28, 28, '028', NULL, NULL, '1', 28, 'Entrega de bienes o servicios a IRULA ROSA MEZA OVIEDO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(29, 29, '029', NULL, NULL, '1', 29, 'Entrega de bienes o servicios a IMACULADA GUARANDA CHAR  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(30, 30, '030', NULL, NULL, '1', 30, 'Entrega de bienes o servicios a REYES EPINAYU  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(31, 31, '031', NULL, NULL, '1', 31, 'Entrega de bienes o servicios a LUZMILA POLO PEÑA  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(32, 32, '032', NULL, NULL, '1', 32, 'Entrega de bienes o servicios a CARLOS MARICHAL VEGLIANTE dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(33, 33, '033', NULL, NULL, '1', 33, 'Entrega de bienes o servicios a GLORIA MARIA TORRES  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(34, 34, '034', NULL, NULL, '1', 34, 'Entrega de bienes o servicios a ARANSIDA AGUILAR GONZALEZ dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(35, 35, '035', NULL, NULL, '1', 35, 'Entrega de bienes o servicios a LUZ MARIA  GUTIERREZ PANA  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(36, 36, '036', NULL, NULL, '1', 36, 'Entrega de bienes o servicios a MARIA ELENA CASTRO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(37, 37, '037', NULL, NULL, '1', 37, 'Entrega de bienes o servicios a JOSE MIGUEL IGUARAN IPUANA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(38, 38, '038', NULL, NULL, '1', 38, 'Entrega de bienes o servicios a LUIS ALFREDO BOLIVAR  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(39, 39, '039', NULL, NULL, '1', 39, 'Entrega de bienes o servicios a ILEIN MILETH PANA  CUETO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(40, 40, '040', NULL, NULL, '1', 40, 'Entrega de bienes o servicios a OMAR ARREGOCES  PRIETO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(41, 41, '041', NULL, NULL, '1', 41, 'Entrega de bienes o servicios a MARÍA FERNÁNDEZ PÁEZ ARIAS dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(42, 42, '042', NULL, NULL, '1', 42, 'Entrega de bienes o servicios a AMAIRANITH ROMERO ROSADO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(43, 43, '043', NULL, NULL, '1', 43, 'Entrega de bienes o servicios a CARLOS ANDRES BERNAL  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(44, 44, '044', NULL, NULL, '1', 44, 'Entrega de bienes o servicios a SILVIRA PUSHAINA URIANA  dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(45, 45, '045', NULL, NULL, '1', 45, 'Entrega de bienes o servicios a ELEMILETH CABAS LÓPEZ dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(46, 46, '046', NULL, NULL, '1', 46, 'Entrega de bienes o servicios a DAINER RAFAEL IGUARAN IPUANA dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(47, 47, '047', NULL, NULL, '1', 47, 'Entrega de bienes o servicios a MIGUEL ANGEL MARICHAL CABALLERO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(48, 48, '048', NULL, NULL, '1', 48, 'Entrega de bienes o servicios a JOSE DOMINGO AMAYA CASTRO dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(49, 49, '049', NULL, NULL, '1', 49, 'Entrega de bienes o servicios a MARTIN LUIS TORRES TOVAR dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(50, 50, '050', NULL, NULL, '1', 50, 'Entrega de bienes o servicios a MARLYS ISABEL JARAMILLO MARTINEZ dentro del marco de la reactivacion Empresarial del municipio de Manaure'),
(51, 51, '051', NULL, NULL, '1', 51, 'Entrega de bienes o servicios a WILBER FRANCISCO DAZA PIMIENTA dentro del marco de la reactivacion Empresarial del municipio de Manaure');


--
-- 0018.contratodetalle
CREATE TABLE IF NOT EXISTS `contratodetalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idcontrato` int(11) NOT NULL,
  `idarticulo` int(11) NOT NULL,
  `estadoarticulo` int(11) NOT NULL,
  `idgestor` int(11) DEFAULT NULL,
  `observacion` varchar(255)  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



INSERT INTO `contratodetalle` (`id`, `idcontrato`, `idarticulo`, `estadoarticulo`, `idgestor`, `observacion`) VALUES
(1, 1, 8, 1, NULL, NULL),
(2, 1, 8, 1, NULL, NULL),
(3, 1, 4, 1, NULL, NULL),
(4, 2, 17, 1, NULL, NULL),
(5, 2, 34, 1, NULL, NULL),
(6, 2, 4, 1, NULL, NULL),
(7, 3, 51, 1, NULL, NULL),
(8, 3, 74, 1, NULL, NULL),
(9, 3, 4, 1, NULL, NULL),
(10, 4, 63, 1, NULL, NULL),
(11, 4, 27, 1, NULL, NULL),
(12, 4, 4, 1, NULL, NULL),
(13, 5, 22, 1, NULL, NULL),
(14, 5, 74, 1, NULL, NULL),
(15, 5, 4, 1, NULL, NULL),
(16, 6, 11, 1, NULL, NULL),
(17, 6, 41, 1, NULL, NULL),
(18, 6, 4, 1, NULL, NULL),
(19, 7, 59, 1, NULL, NULL),
(20, 7, 31, 1, NULL, NULL),
(21, 7, 4, 1, NULL, NULL),
(22, 8, 18, 1, NULL, NULL),
(23, 8, 4, 1, NULL, NULL),
(24, 9, 17, 1, NULL, NULL),
(25, 9, 54, 1, NULL, NULL),
(26, 9, 71, 1, NULL, NULL),
(27, 9, 36, 1, NULL, NULL),
(28, 9, 4, 1, NULL, NULL),
(29, 10, 63, 1, NULL, NULL),
(30, 10, 36, 1, NULL, NULL),
(31, 10, 46, 1, NULL, NULL),
(32, 10, 4, 1, NULL, NULL),
(33, 11, 71, 1, NULL, NULL),
(34, 11, 4, 1, NULL, NULL),
(35, 12, 19, 1, NULL, NULL),
(36, 12, 27, 1, NULL, NULL),
(37, 12, 46, 1, NULL, NULL),
(38, 12, 31, 1, NULL, NULL),
(39, 12, 65, 1, NULL, NULL),
(40, 12, 4, 1, NULL, NULL),
(41, 13, 70, 1, NULL, NULL),
(42, 13, 54, 1, NULL, NULL),
(43, 13, 2, 1, NULL, NULL),
(44, 13, 7, 1, NULL, NULL),
(45, 13, 16, 1, NULL, NULL),
(46, 13, 46, 1, NULL, NULL),
(47, 13, 36, 1, NULL, NULL),
(48, 13, 4, 1, NULL, NULL),
(49, 14, 20, 1, NULL, NULL),
(50, 14, 6, 1, NULL, NULL),
(51, 14, 5, 1, NULL, NULL),
(52, 14, 4, 1, NULL, NULL),
(53, 15, 51, 1, NULL, NULL),
(54, 15, 74, 1, NULL, NULL),
(55, 15, 4, 1, NULL, NULL),
(56, 16, 3, 1, NULL, NULL),
(57, 16, 54, 1, NULL, NULL),
(58, 16, 70, 1, NULL, NULL),
(59, 16, 38, 1, NULL, NULL),
(60, 16, 57, 1, NULL, NULL),
(61, 16, 4, 1, NULL, NULL),
(62, 17, 47, 1, NULL, NULL),
(63, 17, 64, 1, NULL, NULL),
(64, 17, 75, 1, NULL, NULL),
(65, 17, 25, 1, NULL, NULL),
(66, 17, 4, 1, NULL, NULL),
(67, 18, 20, 1, NULL, NULL),
(68, 18, 27, 1, NULL, NULL),
(69, 18, 4, 1, NULL, NULL),
(70, 19, 39, 1, NULL, NULL),
(71, 19, 58, 1, NULL, NULL),
(72, 19, 4, 1, NULL, NULL),
(73, 20, 48, 1, NULL, NULL),
(74, 20, 13, 1, NULL, NULL),
(75, 20, 24, 1, NULL, NULL),
(76, 20, 40, 1, NULL, NULL),
(77, 20, 4, 1, NULL, NULL),
(78, 21, 20, 1, NULL, NULL),
(79, 21, 27, 1, NULL, NULL),
(80, 21, 4, 1, NULL, NULL),
(81, 22, 15, 1, NULL, NULL),
(82, 22, 1, 1, NULL, NULL),
(83, 22, 4, 1, NULL, NULL),
(84, 23, 35, 1, NULL, NULL),
(85, 23, 16, 1, NULL, NULL),
(86, 23, 28, 1, NULL, NULL),
(87, 23, 54, 1, NULL, NULL),
(88, 23, 71, 1, NULL, NULL),
(89, 23, 46, 1, NULL, NULL),
(90, 23, 4, 1, NULL, NULL),
(91, 24, 17, 1, NULL, NULL),
(92, 24, 6, 1, NULL, NULL),
(93, 24, 27, 1, NULL, NULL),
(94, 24, 5, 1, NULL, NULL),
(95, 24, 4, 1, NULL, NULL),
(96, 25, 44, 1, NULL, NULL),
(97, 25, 4, 1, NULL, NULL),
(98, 26, 61, 1, NULL, NULL),
(99, 26, 66, 1, NULL, NULL),
(100, 26, 53, 1, NULL, NULL),
(101, 26, 67, 1, NULL, NULL),
(102, 26, 4, 1, NULL, NULL),
(103, 27, 6, 1, NULL, NULL),
(104, 27, 46, 1, NULL, NULL),
(105, 27, 21, 1, NULL, NULL),
(106, 27, 27, 1, NULL, NULL),
(107, 27, 4, 1, NULL, NULL),
(108, 28, 53, 1, NULL, NULL),
(109, 28, 26, 1, NULL, NULL),
(110, 28, 10, 1, NULL, NULL),
(111, 28, 43, 1, NULL, NULL),
(112, 28, 73, 1, NULL, NULL),
(113, 28, 67, 1, NULL, NULL),
(114, 28, 4, 1, NULL, NULL),
(115, 29, 74, 1, NULL, NULL),
(116, 29, 32, 1, NULL, NULL),
(117, 29, 4, 1, NULL, NULL),
(118, 30, 44, 1, NULL, NULL),
(119, 30, 4, 1, NULL, NULL),
(120, 31, 17, 1, NULL, NULL),
(121, 31, 28, 1, NULL, NULL),
(122, 31, 74, 1, NULL, NULL),
(123, 31, 54, 1, NULL, NULL),
(124, 31, 70, 1, NULL, NULL),
(125, 31, 4, 1, NULL, NULL),
(126, 32, 42, 1, NULL, NULL),
(127, 32, 63, 1, NULL, NULL),
(128, 32, 54, 1, NULL, NULL),
(129, 32, 71, 1, NULL, NULL),
(130, 32, 4, 1, NULL, NULL),
(131, 33, 17, 1, NULL, NULL),
(132, 33, 27, 1, NULL, NULL),
(133, 33, 46, 1, NULL, NULL),
(134, 33, 7, 1, NULL, NULL),
(135, 33, 4, 1, NULL, NULL),
(136, 34, 17, 1, NULL, NULL),
(137, 34, 69, 1, NULL, NULL),
(138, 34, 55, 1, NULL, NULL),
(139, 34, 4, 1, NULL, NULL),
(140, 35, 20, 1, NULL, NULL),
(141, 35, 28, 1, NULL, NULL),
(142, 35, 46, 1, NULL, NULL),
(143, 35, 4, 1, NULL, NULL),
(144, 36, 74, 1, NULL, NULL),
(145, 36, 47, 1, NULL, NULL),
(146, 36, 26, 1, NULL, NULL),
(147, 36, 4, 1, NULL, NULL),
(148, 37, 56, 1, NULL, NULL),
(149, 37, 5, 1, NULL, NULL),
(150, 37, 17, 1, NULL, NULL),
(151, 37, 4, 1, NULL, NULL),
(152, 38, 18, 1, NULL, NULL),
(153, 38, 4, 1, NULL, NULL),
(154, 39, 5, 1, NULL, NULL),
(155, 39, 17, 1, NULL, NULL),
(156, 39, 56, 1, NULL, NULL),
(157, 39, 4, 1, NULL, NULL),
(158, 40, 14, 1, NULL, NULL),
(159, 40, 23, 1, NULL, NULL),
(160, 40, 68, 1, NULL, NULL),
(161, 40, 74, 1, NULL, NULL),
(162, 40, 4, 1, NULL, NULL),
(163, 41, 12, 1, NULL, NULL),
(164, 41, 71, 1, NULL, NULL),
(165, 41, 54, 1, NULL, NULL),
(166, 41, 17, 1, NULL, NULL),
(167, 41, 4, 1, NULL, NULL),
(168, 42, 74, 1, NULL, NULL),
(169, 42, 62, 1, NULL, NULL),
(170, 42, 29, 1, NULL, NULL),
(171, 42, 30, 1, NULL, NULL),
(172, 42, 4, 1, NULL, NULL),
(173, 43, 46, 1, NULL, NULL),
(174, 43, 65, 1, NULL, NULL),
(175, 43, 37, 1, NULL, NULL),
(176, 43, 17, 1, NULL, NULL),
(177, 43, 54, 1, NULL, NULL),
(178, 43, 71, 1, NULL, NULL),
(179, 43, 4, 1, NULL, NULL),
(180, 44, 49, 1, NULL, NULL),
(181, 44, 47, 1, NULL, NULL),
(182, 44, 52, 1, NULL, NULL),
(183, 44, 4, 1, NULL, NULL),
(184, 45, 66, 1, NULL, NULL),
(185, 45, 61, 1, NULL, NULL),
(186, 45, 67, 1, NULL, NULL),
(187, 45, 43, 1, NULL, NULL),
(188, 45, 50, 1, NULL, NULL),
(189, 45, 10, 1, NULL, NULL),
(190, 45, 4, 1, NULL, NULL),
(191, 46, 17, 1, NULL, NULL),
(192, 46, 56, 1, NULL, NULL),
(193, 46, 5, 1, NULL, NULL),
(194, 46, 4, 1, NULL, NULL),
(195, 47, 74, 1, NULL, NULL),
(196, 47, 1, 1, NULL, NULL),
(197, 47, 33, 1, NULL, NULL),
(198, 47, 4, 1, NULL, NULL),
(199, 48, 59, 1, NULL, NULL),
(200, 48, 70, 1, NULL, NULL),
(201, 48, 54, 1, NULL, NULL),
(202, 48, 4, 1, NULL, NULL),
(203, 49, 72, 1, NULL, NULL),
(204, 49, 9, 1, NULL, NULL),
(205, 49, 17, 1, NULL, NULL),
(206, 49, 6, 1, NULL, NULL),
(207, 49, 4, 1, NULL, NULL),
(208, 50, 18, 1, NULL, NULL),
(209, 50, 4, 1, NULL, NULL),
(210, 51, 35, 1, NULL, NULL),
(211, 51, 17, 1, NULL, NULL),
(212, 51, 27, 1, NULL, NULL),
(213, 51, 46, 1, NULL, NULL),
(214, 51, 60, 1, NULL, NULL),
(215, 51, 4, 1, NULL, NULL);


ALTER TABLE `contratodetalle`
  ADD KEY `fk_contratodetalle_contrato` (`idcontrato`),
  ADD KEY `fk_contratodetalle_articulo` (`idarticulo`),
  ADD KEY `fk_contratodetalle_personagestor` (`idgestor`),
  ADD KEY `fk_contratodetalle_estado` (`estadoarticulo`);


--

-- 0019.visitas
CREATE TABLE IF NOT EXISTS  `visitas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fecha` date NOT NULL,
  `idtercero` int(11) NOT NULL,
  `idpersona` int(11) NOT NULL,
  `renovomatricula` int(11) NOT NULL,
  `fecharenovacion` date DEFAULT NULL,
  `direccionactual` varchar(255)  NOT NULL,
  `telefonoactual` varchar(16)  NOT NULL,
  `emailactual` varchar(255)  NOT NULL,
  `generonuevosempleos` int(11) NOT NULL,
  `cuantosempleosformales` int(11) NOT NULL,
  `cuantosempleosinformales` int(11) NOT NULL,
  `capemprendimiento` int(11) DEFAULT NULL,
  `capcontabilidad` int(11) DEFAULT NULL,
  `capsistemas` int(11) DEFAULT NULL,
  `capmarketing` int(11) DEFAULT NULL,
  `capotros` text  DEFAULT NULL,
  `idarchivo` int(11) DEFAULT NULL,
  `idestadolocativa` int(11) DEFAULT NULL,
  `descripcionlocativa` int(11) DEFAULT NULL,
  `descripcionimpacto` text  DEFAULT NULL,
  `incrementoventas` int(11) DEFAULT NULL,
  `iniciotramitecc` int(11) DEFAULT NULL,
  `razonnotramitecc` text  DEFAULT NULL,
  `observacionesgestor` text  NOT NULL,
  `observacionesmicroempresario` int(11) DEFAULT NULL,
  `idrepresentante` int(11) NOT NULL,
  `idgestor` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


ALTER TABLE `visitas`
  ADD KEY `fk_visita_estadolocativa` (`idestadolocativa`),  
  ADD KEY `fk_visita_tercero` (`idtercero`),
  ADD KEY `fk_visita_personaresponsable` (`idpersona`),
  ADD KEY `fk_visita_personagestor` (`idgestor`),
  ADD KEY `fk_visita_personarepresentante` (`idrepresentante`);


--

-- 0020.dofa
CREATE TABLE IF NOT EXISTS  `dofa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `debilidades` text  DEFAULT NULL,
  `fortalezas` text  DEFAULT NULL,
  `oportunidades` text  DEFAULT NULL,
  `amenazas` text  DEFAULT NULL,
  `idvisita` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


ALTER TABLE `dofa`
  ADD KEY `fk_dofas_visita` (`idvisita`);


ALTER TABLE `dofa`
  ADD CONSTRAINT `fk_dofa_visita` FOREIGN KEY (`idvisita`) REFERENCES `visitas` (`id`);

--

-- 0021.segimientoarticulos
CREATE TABLE IF NOT EXISTS  `segimientoarticulos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `idcontrato` int(11) NOT NULL,
  `idarticulo` int(11) NOT NULL,
  `idvisita` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `idestado` int(11) NOT NULL,
  `observaciones` text  NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



ALTER TABLE `segimientoarticulos`
  ADD KEY `fk_segimientoarticulos_visita` (`idvisita`),
  ADD KEY `fk_segimientoarticulos_articulo` (`idarticulo`),
  ADD KEY `fk_segimientoarticulos_estado` (`idestado`),
  ADD KEY `fk_segimientoarticulos_contrato` (`idcontrato`);



--

-- 0022.archivovisitas
CREATE TABLE IF NOT EXISTS `archivovisitas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombrearchivo` varchar(255)  NOT NULL,
  `tipoarchivo` varchar(255)  NOT NULL,
  `rutaarchivo` varchar(255)  NOT NULL,
  `archivo` blob NOT NULL,
  `fecha` date NOT NULL,
  `idarticulo` int(11) NOT NULL,
  `idvisita` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;



ALTER TABLE `archivovisitas`
  ADD KEY `fk_archivovisitas_articulo` (`idarticulo`),
  ADD KEY `fk_archivovisitas_visita` (`idvisita`);


DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_tipoarticulo`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
  set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
	set @tipoarticulo := JSON_VALUE(@parametros,'$.tipoarticulo');

    
    insert into tipoarticulo (
      tipoarticulo 
      )
    select 
      @tipoarticulo
    where not exists(select 1 from tipoarticulo where tipoarticulo=@tipoarticulo and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from Articulo where idtipoarticulo=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from tipoarticulo where id=@id
    and id not in (select coalesce(idtipoarticulo,-1) from Articulo);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
  set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
	set @tipoarticulo := JSON_VALUE(@parametros,'$.tipoarticulo');
  
    update tipoarticulo set  --
      tipoarticulo  = @tipoarticulo
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      tipoarticulo 
    from tipoarticulo   --
    where id=@id; 
  end if;
  
  if @metodo = 'consultartodas' then
	  select 
      id value,
      tipoarticulo  label
    from tipoarticulo; 
  end if;
  

END $$
DELIMITER ;

--
DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_tipoidentificacion`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_VALUE(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
	set @id := JSON_VALUE(@parametros,'$.id');
	set @tipoidentificacion := JSON_VALUE(@parametros,'$.tipoidentificacion');

    
    insert into tipoidentificacion (
        id ,
        tipoidentificacion 
      )
    select 
        @id, 
        @tipoidentificacion
    where not exists(select 1 from tipoidentificacion where id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from personas where tipoidentificacion=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from tipoidentificacion where id=@id
    and id not in (select coalesce(tipoidentificacion,'') from personas);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_VALUE(@parametros,'$.id');
    set @tipoidentificacion := JSON_VALUE(@parametros,'$.tipoidentificacion');
    
    update tipoidentificacion set  --
        tipoidentificacion  = @tipoidentificacion
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	set @id := JSON_VALUE(@parametros,'$.id');
	  select 
      id,
      tipoidentificacion 
    from tipoidentificacion   --
    where id = @id; 
  end if;
  
  if @metodo = 'consultartodas' then
	set @id := JSON_VALUE(@parametros,'$.id');
	  select 
      id value,
      tipoidentificacion label 
    from tipoidentificacion; 
  end if;
  

END $$
DELIMITER ;

--
DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_tipopersona`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @tipopersona := JSON_VALUE(@parametros,'$.tipopersona');
    
    insert into tipopersona (
      tipopersona 
      )
    select 
      @tipopersona
    where not exists(select 1 from tipopersona where tipopersona=@tipopersona and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from personas where idtipopersona=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from tipopersona where id=@id
    and id not in (select coalesce(idtipopersona,-1) from personas);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @tipopersona := JSON_VALUE(@parametros,'$.tipopersona');
    
    update tipopersona set  --
      tipopersona  = @tipopersona
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      tipopersona 
    from tipopersona   --
    where id = @id; 
  end if;
  

  if @metodo = 'consultartodas' then
	  select 
      id value,
      tipopersona label 
    from tipopersona;   --
  end if;
  

END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_estados`(IN js_id int)
BEGIN
  SET @metodo = '';
  SET @metodo = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json, '$.parametros') from api where id=js_id);

  if @metodo = 'nuevo_registro' then
	  SET @usuario_id = (select usuario_id from api where id=js_id);
    set @estado := JSON_VALUE(@parametros,'$.estado');

    insert into estados (estado)
    select @estado
    where not exists(select 1 from estados where estado=@estado);
  end if;

  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    select false as elimininar;
    if not exists(select 1 from Articulo where estado=@id) then 
      if  exists(select 1 from contratodetalle where estadoarticulo=@id) then 
        select false as eliminar;
      else   
        if  exists(select 1 from visitas where estadolocativa=@id) then
          select false as eliminar;
        else 
          select true as eliminar;
        end if;
      end if;
    else  
      select true as eliminar;
    end if;
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    delete from estados where id=@id;
    -- and id not in (select coalesce(grupo_id,-1) from usu);
  end if;

  if @metodo = 'editar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    set @estado := JSON_VALUE(@parametros,'$.estado');
    update estados set estado=@estado
    where id=@id;
  end if;

  if @metodo = 'consultar' then
	  select 
      id,
      estado 
    from estados   --
    where id = @id; 
  end if;
  
  if @metodo = 'consultartodas' then
	  select 
      id value,
      estado label
    from estados; 
  end if;
  
END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_departamentos`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
	set @id := JSON_VALUE(@parametros,'$.id');
	set @departamento := JSON_VALUE(@parametros,'$.departamento');

    
    insert into departamentos (
      id,
      departamento 
      )
    select 
      @id,
      @departamento
    where not exists(select 1 from departamentos where departamento=@departamento and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from ciudades where iddepartamento=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from departamentos where id=@id
    and id not in (select coalesce(iddepartamento,-1) from ciudades);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_VALUE(@parametros,'$.id');
    set @departamento := JSON_VALUE(@parametros,'$.departamento');
    
    update departamentos set  --
      id            = @id,
      departamento  = @departamento
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      departamento 
    from departamentos   --
    where id = @id; 
  end if;
  
  if @metodo = 'consultartodas' then
	  select 
      id value,
      departamento label
    from departamentos; 
  end if;
  

END $$
DELIMITER ;

---

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_clasepersona`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @clasepersona := JSON_VALUE(@parametros,'$.clasepersona');
    
    insert into clasepersona (
      clasepersona 
      )
    select 
      @clasepersona
    where not exists(select 1 from clasepersona where clasepersona=@clasepersona and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from terceros where idclasepersona=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from clasepersona where id=@id
    and id not in (select coalesce(idclasepersona,-1) from terceros);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @clasepersona := JSON_VALUE(@parametros,'$.clasepersona');
    
    update clasepersona set  --
      clasepersona  = @clasepersona
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id value,
      clasepersona label 
    from clasepersona   --
    where id = @id; 
  end if;
  

END $$
DELIMITER ;

--


DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_ciudades`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
	set @id := JSON_VALUE(@parametros,'$.id');
	set @ciudad := JSON_VALUE(@parametros,'$.ciudad');
	set @iddepartamento := JSON_VALUE(@parametros,'$.iddepartamento');

    
    insert into ciudades (
        id,
        ciudad ,
        iddepartamento
      )
    select 
        @id,
        @ciudad,
        @iddepartamento
    where not exists(select 1 from ciudades where ciudad=@ciudad and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from terceros where ciudad=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from personas where ciudad=@id) then
            select false as eliminar;
        else
            select true as eliminar;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from ciudades where id=@id
    and id not in (select coalesce(ciudad,-1) from terceros)
    and id not in (select coalesce(ciudad,-1) from personas)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_VALUE(@parametros,'$.id');
    set @ciudad := JSON_VALUE(@parametros,'$.ciudad');
	set @iddepartamento := JSON_VALUE(@parametros,'$.iddepartamento');
    
    update ciudades set  --
        ciudad = @ciudad ,
        iddepartamento = @iddepartamento
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      ciudades.id,
      ciudades.ciudad ,
      departamentos.id,
      departamentos.departamento
    from ciudades inner join departamentos on ciudades.iddepartamento = departamentos.id  --
    where ciudades.id = @id; 
  end if;
  

END $$
DELIMITER ;

--


DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_sector`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @nombre := JSON_VALUE(@parametros,'$.nombre');
    
    insert into sector (
      nombre 
      )
    select 
      @nombre
    where not exists(select 1 from sector where nombre=@nombre and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from terceros where idsector=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from sector where id=@id
    and id not in (select coalesce(idsector,-1) from terceros);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @nombre := JSON_VALUE(@parametros,'$.nombre');

    update sector set  --
      nombre  = @nombre
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      nombre 
    from sector   --
    where id = @id; 
  end if;

  if @metodo = 'consultartodas' then
	 select 
    id value , 
    nombre label 
   from sector;  --
    
  end if;
  

END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_Articulo`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @nombre           := JSON_VALUE(@parametros,'$.nombre');
    set @idtipoarticulo   := JSON_VALUE(@parametros,'$.idtipoarticulo');
    set @estado           := JSON_VALUE(@parametros,'$.estado');
    set @observaciones    := JSON_VALUE(@parametros,'$.observaciones');
    set @caracteristicas  := JSON_VALUE(@parametros,'$.caracteristicas');

    
    insert into Articulo (
        nombre,
        idtipoarticulo,
        estado,
        observaciones,
        caracteristicas
      )
    select 
        @nombre,
        @idtipoarticulo,
        @estado,
        @observaciones,
        @caracteristicas
    where not exists(select 1 from Articulo where nombre=@nombre and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from contratodetalle where idarticulo=@id) then
      select false as eliminar;
    else
      if  exists(select 1 from segimientoarticulos where idarticulo=@id) then
            select false as eliminar;
        else
            select true as eliminar;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from Articulo where id=@id
    and id not in (select coalesce(idarticulo,-1) from contratodetalle)
    and id not in (select coalesce(idarticulo,-1) from segimientoarticulos)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @nombre           := JSON_VALUE(@parametros,'$.nombre');
    set @idtipoarticulo   := JSON_VALUE(@parametros,'$.idtipoarticulo');
    set @estado           := JSON_VALUE(@parametros,'$.estado');
    set @observaciones    := JSON_VALUE(@parametros,'$.observaciones');
    set @caracteristicas  := JSON_VALUE(@parametros,'$.caracteristicas');
    
    update Articulo set  --
        nombre              = @nombre,
        idtipoarticulo      = @idtipoarticulo,
        estado              = @estado,
        observaciones       = @observaciones,
        caracteristicas     = @caracteristicas
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        Articulo.nombre,
        Articulo.idtipoarticulo,
        Articulo.estado,
        Articulo.observaciones,
        Articulo.caracteristicas,
        tipoarticulo.tipoarticulo
    from Articulo  inner join tipoarticulo on Articulo.idtipoarticulo= tipoarticulo.id --
    where Articulo.id = @id; 
  end if;
  

END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_personas`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @pnombre             := JSON_VALUE(@parametros,'$.pnombre');
    set @snombre             := JSON_VALUE(@parametros,'$.snombre');
    set @papellido           := JSON_VALUE(@parametros,'$.papellido');
    set @sapellido           := JSON_VALUE(@parametros,'$.sapellido');
    set @idtipopersona       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtipopersona'));
    set @sexo                := JSON_VALUE(@parametros,'$.sexo');
    set @edad                := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.edad'));
    set @direccion           := JSON_VALUE(@parametros,'$.direccion');
    set @telefonocel         := JSON_VALUE(@parametros,'$.telefonocel');
    set @email               := JSON_VALUE(@parametros,'$.email');
    set @tipoidentificacion  := JSON_VALUE(@parametros,'$.tipoidentificacion');
    set @noidentificacion    := JSON_VALUE(@parametros,'$.noidentificacion');
    set @ciudad              := JSON_VALUE(@parametros,'$.ciudad');
    set @usuario             := JSON_VALUE(@parametros,'$.usuario');
    set @clave               := JSON_VALUE(@parametros,'$.clave');

    
    insert into personas (
        pnombre,
        snombre,
        papellido,
        sapellido,
        idtipopersona,
        sexo,
        edad,
        direccion,
        telefonocel,
        email,
        tipoidentificacion,
        noidentificacion,
        ciudad,
        usuario,
        clave
      )
    select 
        @pnombre,
        @snombre,
        @papellido,
        @sapellido,
        @idtipopersona,
        @sexo,
        @edad,
        @direccion,
        @telefonocel,
        @email,
        @tipoidentificacion,
        @noidentificacion,
        @ciudad,
        @usuario,
        @clave
    where not exists(select 1 from personas where noidentificacion=@noidentificacion ); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from terceros where @id = idrepresentante ) then
      select false as eliminar;
    else
        if  exists(select 1 from visitas where @id in ( idpersona, idrepresentante , idgestor )) then
            select false as eliminar;
        else
            if  exists(select 1 from contratodetalle where @id = idgestor ) then
                select false as eliminar;
            else
                if  exists(select 1 from contratos where @id = idrepresentante ) then
                    select false as eliminar;
                else
                    select true as eliminar;
                end if;
            end if;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from personas where id=@id
    and id not in (select coalesce(idrepresentante,-1) from contratos)
    and id not in (select coalesce(idrepresentante,-1) from terceros)
    and id not in (select coalesce(idrepresentante,-1) from visitas)
    and id not in (select coalesce(idpersona,-1) from visitas)
    and id not in (select coalesce(idgestor,-1) from visitas)
    and id not in (select coalesce(idgestor,-1) from contratodetalle)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @pnombre             := JSON_VALUE(@parametros,'$.pnombre');
    set @snombre             := JSON_VALUE(@parametros,'$.snombre');
    set @papellido           := JSON_VALUE(@parametros,'$.papellido');
    set @sapellido           := JSON_VALUE(@parametros,'$.sapellido');
    set @idtipopersona       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtipopersona'));
    set @sexo                := JSON_VALUE(@parametros,'$.sexo');
    set @edad                := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.edad'));
    set @direccion           := JSON_VALUE(@parametros,'$.direccion');
    set @telefonocel         := JSON_VALUE(@parametros,'$.telefonocel');
    set @email               := JSON_VALUE(@parametros,'$.email');
    set @tipoidentificacion  := JSON_VALUE(@parametros,'$.tipoidentificacion');
    set @noidentificacion    := JSON_VALUE(@parametros,'$.noidentificacion');
    set @ciudad              := JSON_VALUE(@parametros,'$.ciudad');
    set @usuario             := JSON_VALUE(@parametros,'$.usuario');
    set @clave               := JSON_VALUE(@parametros,'$.clave');
    
    update personas set  --
        pnombre             =   @pnombre,
        snombre             =   @snombre,
        papellido           =   @papellido,
        sapellido           =   @sapellido,
        idtipopersona       =   @idtipopersona,
        sexo                =   @sexo,
        edad                =   @edad,
        direccion           =   @direccion,
        telefonocel         =   @telefonocel,
        email               =   @email,
        tipoidentificacion  =   @tipoidentificacion,
        noidentificacion    =   @noidentificacion,
        ciudad              =   @ciudad,
        usuario             =   @usuario,
        clave               =   @clave
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        personas.pnombre,
        personas.snombre,
        personas.papellido,
        personas.sapellido,
        personas.idtipopersona,
        personas.sexo,
        personas.edad,
        personas.direccion,
        personas.telefonocel,
        personas.email,
        personas.tipoidentificacion,
        personas.noidentificacion,
        personas.ciudad,
        personas.usuario,
        personas.clave,
        tipopersona.tipopersona,
        tipoidentificacion.tipoidentificacion,
        ciudades.ciudad
    from personas 
        inner join tipopersona on personas.idtipopersona = tipopersona.id  --
        inner join tipoidentificacion on personas.tipoidentificacion= tipoidentificacion.id  --
        inner join ciudades on personas.ciudad= ciudades.id  --
    where personas.id = @id; 
  end if;
  

END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_terceros`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @NIT                       := JSON_VALUE(@parametros,'$.NIT');
    set @razonsocial               := JSON_VALUE(@parametros,'$.razonsocial');
    set @registradoencc            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.registradoencc'));
    set @matriculaencc             := JSON_VALUE(@parametros,'$.matriculaencc');
    set @fechaconstitucion         := JSON_VALUE(@parametros,'$.fechaconstitucion');
    set @tipocontribuyente         := JSON_VALUE(@parametros,'$.tipocontribuyente');
    set @ciudad                    := JSON_VALUE(@parametros,'$.ciudad');
    set @telefonocel               := JSON_VALUE(@parametros,'$.telefonocel');
    set @email                     := JSON_VALUE(@parametros,'$.email');
    set @direccion                 := JSON_VALUE(@parametros,'$.direccion');
    set @telefonofijo              := JSON_VALUE(@parametros,'$.telefonofijo');
    set @idrepresentante           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idsector                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idsector'));
    set @cantidadempleosformales   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosformales'));
    set @cantidadempleosinformales := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosinformales'));
    set @idclasepersona            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idclasepersona'));

    insert into terceros (
        NIT,
        razonsocial,
        registradoencc,
        matriculaencc,
        fechaconstitucion,
        tipocontribuyente,
        ciudad,
        telefonocel,
        email,
        direccion,
        telefonofijo,
        idrepresentante,
        idsector,
        cantidadempleosformales,
        cantidadempleosinformales,
        idclasepersona
      )
    select 
        @NIT,
        @razonsocial,
        @registradoencc,
        @matriculaencc,
        @fechaconstitucion,
        @tipocontribuyente,
        @ciudad,
        @telefonocel,
        @email,
        @direccion,
        @telefonofijo,
        @idrepresentante,
        @idsector,
        @cantidadempleosformales,
        @cantidadempleosinformales,
        @idclasepersona
    where not exists(select 1 from terceros where NIT=NIT and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from contratos where id=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from visitas where id=@id) then
            select false as eliminar;
        else
            select true as eliminar;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from terceros where id=@id
    and id not in (select coalesce(id,-1) from contratos)
    and id not in (select coalesce(id,-1) from visitas)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @NIT                       := JSON_VALUE(@parametros,'$.NIT');
    set @razonsocial               := JSON_VALUE(@parametros,'$.razonsocial');
    set @registradoencc            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.registradoencc'));
    set @matriculaencc             := JSON_VALUE(@parametros,'$.matriculaencc');
    set @fechaconstitucion         := JSON_VALUE(@parametros,'$.fechaconstitucion');
    set @tipocontribuyente         := JSON_VALUE(@parametros,'$.tipocontribuyente');
    set @ciudad                    := JSON_VALUE(@parametros,'$.ciudad');
    set @telefonocel               := JSON_VALUE(@parametros,'$.telefonocel');
    set @email                     := JSON_VALUE(@parametros,'$.email');
    set @direccion                 := JSON_VALUE(@parametros,'$.direccion');
    set @telefonofijo              := JSON_VALUE(@parametros,'$.telefonofijo');
    set @idrepresentante           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idsector                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idsector'));
    set @cantidadempleosformales   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosformales'));
    set @cantidadempleosinformales := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosinformales'));
    set @idclasepersona            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idclasepersona'));
    
    update terceros set  --
        NIT                       = @NIT ,
        razonsocial               = @razonsocial ,
        registradoencc            = @registradoencc ,
        matriculaencc             = @matriculaencc ,
        fechaconstitucion         = @fechaconstitucion ,
        tipocontribuyente         = @tipocontribuyente ,
        ciudad                    = @ciudad ,
        telefonocel               = @telefonocel ,
        email                     = @email ,
        direccion                 = @direccion ,
        telefonofijo              = @telefonofijo ,
        idrepresentante           = @idrepresentante ,
        idsector                  = @idsector ,
        cantidadempleosformales   = @cantidadempleosformales ,
        cantidadempleosinformales = @cantidadempleosinformales ,
        idclasepersona            = @idclasepersona 
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        t.NIT,
        t.razonsocial,
        t.registradoencc,
        t.matriculaencc,
        t.fechaconstitucion,
        t.tipocontribuyente,
        t.ciudad,
        t.telefonocel,
        t.email,
        t.direccion,
        t.telefonofijo,
        t.idrepresentante,
        t.idsector,
        t.cantidadempleosformales,
        t.cantidadempleosinformales,
        t.idclasepersona,
        ciudades.ciudad,
        concat(p.papellido, ' ' , p.sapellido , ' ' , p.pnombre, ' ', p.snombre ) as nombrepersona,
        concat(representante.papellido, ' ' , representante.sapellido , ' ' , representante.pnombre, ' ', representante.snombre ) as nombrerepresentante,
        concat(gestor.papellido, ' ' , gestor.sapellido , ' ' , gestor.pnombre, ' ', gestor.snombre ) as nombregestor

    from terceros t
        inner join ciudades on t.ciudad = ciudades.id  --
        inner join personas p on t.idpersona = p.id  --
        inner join personas representante on t.idpersona = representante.id  --
        inner join personas gestor on t.idpersona = gestor.id  --
    where t.id = @id; 
  end if;
  

END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_contratos`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                    := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idtercero             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @referencianumero      := JSON_VALUE(@parametros,'$.referencianumero');
    set @fecha                 := JSON_VALUE(@parametros,'$.fecha');
    set @tipo                  := JSON_VALUE(@parametros,'$.tipo');
    set @idrepresentante       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @necesitacapacitacion  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.necesitacapacitacion'));
    set @detalle               := JSON_VALUE(@parametros,'$.detalle');

    
    insert into contratos (
        idtercero,
        referencianumero,
        fecha,
        tipo,
        idrepresentante,
        necesitacapacitacion,
        detalle
      )
    select 
        @idtercero,
        @referencianumero,
        @fecha,
        @tipo,
        @idrepresentante,
        @necesitacapacitacion,
        @detalle
    where not exists(select 1 from contratos where  id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from contratodetalle where idcontrato=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from segimientoarticulos where idcontrato=@id) then
            select false as eliminar;
        else
            select true as eliminar;
        end if;
        
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from contratos where id=@id
    and id not in (select coalesce(idcontrato,-1) from contratodetalle)
    and id not in (select coalesce(idcontrato,-1) from segimientoarticulos)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                    := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idtercero             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @referencianumero      := JSON_VALUE(@parametros,'$.referencianumero');
    set @fecha                 := JSON_VALUE(@parametros,'$.fecha');
    set @tipo                  := JSON_VALUE(@parametros,'$.tipo');
    set @idrepresentante       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @necesitacapacitacion  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.necesitacapacitacion'));
    set @detalle               := JSON_VALUE(@parametros,'$.detalle');
    
    update contratos set  --
        idtercero             = @idtercero,
        referencianumero      = @referencianumero,
        fecha                 = @fecha,
        tipo                  = @tipo,
        idrepresentante       = @idrepresentante,
        necesitacapacitacion  = @necesitacapacitacion,
        detalle               = @detalle
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        c.id,
        c.idtercero,
        c.referencianumero,
        c.fecha,
        c.tipo,
        c.idrepresentante,
        c.necesitacapacitacion,
        c.detalle,
        concat( personas.papellido , ' ' , personas.sapellido ,' ' , personas.pnombre , ' ' , personas.snombre ) nombrerepresentante
    from contratos c
            inner join  personas  on c.idrepresentante =personas.id --
    where c.id=@id; 
  end if;
  

END $$
DELIMITER ;


--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_contratodetalle`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idcontrato     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idcontrato'));
    set @idarticulo     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @estadoarticulo := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.estadoarticulo'));
    set @idgestor       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));
    set @observacion    := JSON_VALUE(@parametros,'$.observacion');

    
    insert into contratodetalle (
        idcontrato,
        idarticulo,
        estadoarticulo,
        idgestor,
        observacion 
      )
    select 
        @idcontrato,
        @idarticulo,
        @estadoarticulo,
        @idgestor,
        @observacion
    where not exists(select 1 from contratodetalle where idcontrato=@idcontrato and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    -- if  exists(select 1 from personas where idcontratodetalle=@id) then
    --   select false as eliminar;
    -- else
        select true as eliminar;
    -- end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from contratodetalle where id=@id
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idcontrato     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idcontrato'));
    set @idarticulo     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @estadoarticulo := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.estadoarticulo'));
    set @idgestor       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));
    set @observacion    := JSON_VALUE(@parametros,'$.observacion');

    
    update contratodetalle set  --
        idcontrato      = @idcontrato ,
        idarticulo      = @idarticulo ,
        estadoarticulo  = @estadoarticulo ,
        idgestor        = @idgestor ,
        observacion     = @observacion 
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        c.idcontrato,
        c.idarticulo,
        c.estadoarticulo,
        c.idgestor,
        c.observacion,
        Articulo.nombre,
        estados.estado,
        concat( personas.papellido , ' ' , personas.sapellido ,' ' , personas.pnombre , ' ' , personas.snombre ) nombregestor
    from contratodetalle  c 
            inner join Articulo on Articulo.id =c.idarticulo
            inner join estados on estados.id= c.estadoarticulo
            inner join personas on personas.id= c.idgestor--
    where c.id = @id; 
  end if;
  

END $$
DELIMITER ;

--



--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_dofa`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @debilidades   := JSON_VALUE(@parametros,'$.debilidades');
    set @fortalezas    := JSON_VALUE(@parametros,'$.fortalezas');
    set @oportunidades := JSON_VALUE(@parametros,'$.oportunidades');
    set @amenazas      := JSON_VALUE(@parametros,'$.amenazas');
    set @idvisita      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));

    
    insert into dofa (
        debilidades,
        fortalezas,
        oportunidades,
        amenazas,
        idvisita
      )
    select 
        @debilidades,
        @fortalezas,
        @oportunidades,
        @amenazas,
        @idvisita
    where not exists(select 1 from dofa where idvisita=@idvisita and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    -- if  exists(select 1 from terceros where iddofa=@id) then
    --   select false as eliminar;
    -- else
        select true as eliminar;
    -- end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from dofa where id=@id
    -- and id not in (select coalesce(iddofa,-1) from terceros)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @debilidades   := JSON_VALUE(@parametros,'$.debilidades');
    set @fortalezas    := JSON_VALUE(@parametros,'$.fortalezas');
    set @oportunidades := JSON_VALUE(@parametros,'$.oportunidades');
    set @amenazas      := JSON_VALUE(@parametros,'$.amenazas');
    set @idvisita      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));

    update dofa set  --
        debilidades  = @debilidades ,
        fortalezas   = @fortalezas ,
        oportunidades= @oportunidades ,
        amenazas     = @amenazas ,
        idvisita     = @idvisita 
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        id,
        debilidades,
        fortalezas,
        oportunidades,
        amenazas,
        idvisita
    from dofa   --
    where id = @id; 
  end if;
  

END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_segimientoarticulos`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idcontrato       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idcontrato'));
    set @idarticulo       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @idvisita         := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));
    set @cantidad         := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidad'));
    set @idestado         := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idestado'));
    set @observaciones    := JSON_VALUE(@parametros,'$.observaciones');

    
    insert into segimientoarticulos (
        idcontrato,
        idarticulo,
        idvisita,
        cantidad,
        idestado,
        observaciones
      )
    select 
        @idcontrato,
        @idarticulo,
        @idvisita,
        @cantidad,
        @idestado,
        @observaciones
    where not exists(select 1 from segimientoarticulos where idvisita=@idvisita and idarticulo=@idarticulo and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    -- if  exists(select 1 from terceros where idsegimientoarticulos=@id) then
    --   select false as eliminar;
    -- else
        select true as eliminar;
    -- end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from segimientoarticulos where id=@id   ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idcontrato       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idcontrato'));
    set @idarticulo       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @idvisita         := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));
    set @cantidad         := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidad'));
    set @idestado         := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idestado'));
    set @observaciones    := JSON_VALUE(@parametros,'$.observaciones');
    
    update segimientoarticulos set  --
        idcontrato      = @idcontrato,
        idarticulo      = @idarticulo,
        idvisita        = @idvisita,
        cantidad        = @cantidad,
        idestado        = @idestado,
        observaciones   = @observaciones
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        s.id,
        s.idcontrato,
        s.idarticulo,
        s.idvisita,
        s.cantidad,
        s.idestado,
        s.observaciones,
        Articulo.nombre,
        estados.estado
    from segimientoarticulos s 
            inner join Articulo on Articulo.id =s.idarticulo
            inner join estados on estados.id =s.idestado
             --
    where s.id = @id; 
  end if;
  

END $$
DELIMITER ;

--
DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_archivovisitas`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @nombrearchivo   := JSON_VALUE(@parametros,'$.nombrearchivo');
    set @tipoarchivo     := JSON_VALUE(@parametros,'$.tipoarchivo');
    set @rutaarchivo     := JSON_VALUE(@parametros,'$.rutaarchivo');
    set @archivo         := JSON_VALUE(@parametros,'$.archivo');
    set @fecha           := JSON_VALUE(@parametros,'$.fecha');
    set @idarticulo      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @idvisita        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));

    insert into archivovisitas (
        nombrearchivo,
        tipoarchivo,
        rutaarchivo,
        archivo,
        fecha,
        idarticulo,
        idvisita
      )
    select 
        @nombrearchivo,
        @tipoarchivo,
        @rutaarchivo,
        @archivo,
        @fecha,
        @idarticulo,
        @idvisita
    where not exists(select 1 from archivovisitas where nombrearchivo=@nombrearchivo and tipoarchivo=@tipoarchivo and rutaarchivo=@rutaarchivo and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    -- if  exists(select 1 from terceros where idarchivovisitas=@id) then
    --   select false as eliminar;
    -- else
            select true as eliminar;
    -- end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from archivovisitas where id=@id;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @nombrearchivo   := JSON_VALUE(@parametros,'$.nombrearchivo');
    set @tipoarchivo     := JSON_VALUE(@parametros,'$.tipoarchivo');
    set @rutaarchivo     := JSON_VALUE(@parametros,'$.rutaarchivo');
    set @archivo         := JSON_VALUE(@parametros,'$.archivo');
    set @fecha           := JSON_VALUE(@parametros,'$.fecha');
    set @idarticulo      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @idvisita        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));

    update archivovisitas set  --
        nombrearchivo = @nombrearchivo,
        tipoarchivo   = @tipoarchivo,
        rutaarchivo   = @rutaarchivo,
        archivo       = @archivo,
        fecha         = @fecha,
        idarticulo    = @idarticulo,
        idvisita      = @idvisita
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        id,
        nombrearchivo,
        tipoarchivo,
        rutaarchivo,
        archivo,
        fecha,
        idarticulo,
        idvisita
    from archivovisitas   --
    where id = @id; 
  end if;
  

END $$
DELIMITER ;

--

DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_visitas`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @fecha                         := JSON_VALUE(@parametros,'$.fecha');
    set @idtercero                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @idpersona                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idpersona'));
    set @renovomatricula               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.renovomatricula'));
    set @fecharenovacion               := JSON_VALUE(@parametros,'$.fecharenovacion');
    set @direccionactual               := JSON_VALUE(@parametros,'$.direccionactual');
    set @telefonoactual                := JSON_VALUE(@parametros,'$.telefonoactual');
    set @emailactual                   := JSON_VALUE(@parametros,'$.emailactual');
    set @generonuevosempleos           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.generonuevosempleos'));
    set @cuantosempleosformales        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosformales'));
    set @cuantosempleosinformales      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosinformales'));
    set @capemprendimiento             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capemprendimiento'));
    set @capcontabilidad               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capcontabilidad'));
    set @capsistemas                   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capsistemas'));
    set @capmarketing                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capmarketing'));
    set @capotros                      := JSON_VALUE(@parametros,'$.capotros');
    set @idarchivo                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarchivo'));
    set @idestadolocativa              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idestadolocativa'));
    set @descripcionlocativa           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.descripcionlocativa'));
    set @descripcionimpacto            := JSON_VALUE(@parametros,'$.descripcionimpacto');
    set @incrementoventas              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.incrementoventas'));
    set @iniciotramitecc               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.iniciotramitecc'));
    set @razonnotramitecc              := JSON_VALUE(@parametros,'$.razonnotramitecc');
    set @observacionesgestor           := JSON_VALUE(@parametros,'$.observacionesgestor');
    set @observacionesmicroempresario  := JSON_VALUE(@parametros,'$.observacionesmicroempresario');
    set @idrepresentante               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idgestor                      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));

    
    insert into visitas (
        fecha,
        idtercero,
        idpersona,
        renovomatricula,
        fecharenovacion,
        direccionactual,
        telefonoactual,
        emailactual,
        generonuevosempleos,
        cuantosempleosformales,
        cuantosempleosinformales,
        capemprendimiento,
        capcontabilidad,
        capsistemas,
        capmarketing,
        capotros,
        idarchivo,
        idestadolocativa,
        descripcionlocativa,
        descripcionimpacto,
        incrementoventas,
        iniciotramitecc,
        razonnotramitecc,
        observacionesgestor,
        observacionesmicroempresario,
        idrepresentante,
        idgestor
      )
    select 
        @fecha,
        @idtercero,
        @idpersona,
        @renovomatricula,
        @fecharenovacion,
        @direccionactual,
        @telefonoactual,
        @emailactual,
        @generonuevosempleos,
        @cuantosempleosformales,
        @cuantosempleosinformales,
        @capemprendimiento,
        @capcontabilidad,
        @capsistemas,
        @capmarketing,
        @capotros,
        @idarchivo,
        @idestadolocativa,
        @descripcionlocativa,
        @descripcionimpacto,
        @incrementoventas,
        @iniciotramitecc,
        @razonnotramitecc,
        @observacionesgestor,
        @observacionesmicroempresario,
        @idrepresentante,
        @idgestor
    where not exists(select 1 from visitas where fecha=@fecha and idtercero=@idtercero and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');

    -- VALIDA LAS FK    
    if  exists(select 1 from archivovisitas where idvisitas=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from dofa where idvisitas=@id) then
            select false as eliminar;
        else
            if  exists(select 1 from segimientoarticulos where idvisitas=@id) then
                select false as eliminar;
            else
                select true as eliminar;
            end if;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from visitas where id=@id
    and id not in (select coalesce(idvisitas,-1) from archivovisitas)
    and id not in (select coalesce(idvisitas,-1) from dofa)
    and id not in (select coalesce(idvisitas,-1) from segimientoarticulos)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @fecha                         := JSON_VALUE(@parametros,'$.fecha');
    set @idtercero                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @idpersona                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idpersona'));
    set @renovomatricula               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.renovomatricula'));
    set @fecharenovacion               := JSON_VALUE(@parametros,'$.fecharenovacion');
    set @direccionactual               := JSON_VALUE(@parametros,'$.direccionactual');
    set @telefonoactual                := JSON_VALUE(@parametros,'$.telefonoactual');
    set @emailactual                   := JSON_VALUE(@parametros,'$.emailactual');
    set @generonuevosempleos           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.generonuevosempleos'));
    set @cuantosempleosformales        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosformales'));
    set @cuantosempleosinformales      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosinformales'));
    set @capemprendimiento             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capemprendimiento'));
    set @capcontabilidad               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capcontabilidad'));
    set @capsistemas                   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capsistemas'));
    set @capmarketing                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capmarketing'));
    set @capotros                      := JSON_VALUE(@parametros,'$.capotros');
    set @idarchivo                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarchivo'));
    set @idestadolocativa              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idestadolocativa'));
    set @descripcionlocativa           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.descripcionlocativa'));
    set @descripcionimpacto            := JSON_VALUE(@parametros,'$.descripcionimpacto');
    set @incrementoventas              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.incrementoventas'));
    set @iniciotramitecc               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.iniciotramitecc'));
    set @razonnotramitecc              := JSON_VALUE(@parametros,'$.razonnotramitecc');
    set @observacionesgestor           := JSON_VALUE(@parametros,'$.observacionesgestor');
    set @observacionesmicroempresario  := JSON_VALUE(@parametros,'$.observacionesmicroempresario');
    set @idrepresentante               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idgestor                      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));
    
    update visitas set  --
        fecha                           = @fecha,
        idtercero                       = @idtercero,
        idpersona                       = @idpersona,
        renovomatricula                 = @renovomatricula,
        fecharenovacion                 = @fecharenovacion,
        direccionactual                 = @direccionactual,
        telefonoactual                  = @telefonoactual,
        emailactual                     = @emailactual,
        generonuevosempleos             = @generonuevosempleos,
        cuantosempleosformales          = @cuantosempleosformales,
        cuantosempleosinformales        = @cuantosempleosinformales,
        capemprendimiento               = @capemprendimiento,
        capcontabilidad                 = @capcontabilidad,
        capsistemas                     = @capsistemas,
        capmarketing                    = @capmarketing,
        capotros                        = @capotros,
        idarchivo                       = @idarchivo,
        idestadolocativa                = @idestadolocativa,
        descripcionlocativa             = @descripcionlocativa,
        descripcionimpacto              = @descripcionimpacto,
        incrementoventas                = @incrementoventas,
        iniciotramitecc                 = @iniciotramitecc,
        razonnotramitecc                = @razonnotramitecc,
        observacionesgestor             = @observacionesgestor,
        observacionesmicroempresario    = @observacionesmicroempresario,
        idrepresentante                 = @idrepresentante,
        idgestor                        = @idgestor
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        v.fecha,
        v.idtercero,
        v.idpersona,
        v.renovomatricula,
        v.fecharenovacion,
        v.direccionactual,
        v.telefonoactual,
        v.emailactual,
        v.generonuevosempleos,
        v.cuantosempleosformales,
        v.cuantosempleosinformales,
        v.capemprendimiento,
        v.capcontabilidad,
        v.capsistemas,
        v.capmarketing,
        v.capotros,
        v.idarchivo,
        v.idestadolocativa,
        v.descripcionlocativa,
        v.descripcionimpacto,
        v.incrementoventas,
        v.iniciotramitecc,
        v.razonnotramitecc,
        v.observacionesgestor,
        v.observacionesmicroempresario,
        v.idrepresentante,
        v.idgestor,
        terceros.razonsocial,
        terceros.NIT,
        concat( personas.papellido , ' ' , personas.sapellido ,' ' , personas.pnombre , ' ' , personas.snombre ) nombrepersona,
        concat( representante.papellido , ' ' , representante.sapellido ,' ' , representante.pnombre , ' ' , representante.snombre ) nombrerepresentante,
        concat( gestor.papellido , ' ' , gestor.sapellido ,' ' , gestor.pnombre , ' ' , gestor.snombre ) nombregestor


    from visitas v 
            inner join terceros on v.idtercero = terceros.id
            inner join personas on v.idpersonas = personas.id
            inner join personas representante on v.idpersona = representante.id  --
            inner join personas gestor on v.idpersona = gestor.id  --
            inner join estados on v.idestadolocativas = estados.id
             --
    where v.id = @id; 
  end if;
  

END $$
DELIMITER ;



ALTER TABLE `contratodetalle` ADD CONSTRAINT `fk_contratodetalle_estado` FOREIGN KEY (`estadoarticulo`) REFERENCES `Articulo`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
 
ALTER TABLE `contratodetalle` ADD CONSTRAINT `fk_contratodetalle_articulo` FOREIGN KEY (`idarticulo`) REFERENCES `Articulo`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `contratodetalle` ADD CONSTRAINT `fk_contratodetalle_contrato` FOREIGN KEY (`idcontrato`) REFERENCES `contratos`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `contratodetalle` ADD CONSTRAINT `fk_contratodetalle_personagestor` FOREIGN KEY (`idgestor`) REFERENCES `personas`(`id`) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE `visitas`
  ADD CONSTRAINT `fk_visita_estadolocativa` FOREIGN KEY (`idestadolocativa`) REFERENCES `estados` (`id`),
  ADD CONSTRAINT `fk_visita_personagestor` FOREIGN KEY (`idgestor`) REFERENCES `personas` (`id`),
  ADD CONSTRAINT `fk_visita_personarepresentante` FOREIGN KEY (`idrepresentante`) REFERENCES `personas` (`id`),
  ADD CONSTRAINT `fk_visita_personaresponsable` FOREIGN KEY (`idpersona`) REFERENCES `personas` (`id`),
  ADD CONSTRAINT `fk_visita_tercero` FOREIGN KEY (`idtercero`) REFERENCES `terceros` (`id`);

ALTER TABLE `segimientoarticulos`
  ADD CONSTRAINT `fk_segimientoarticulos_visita` FOREIGN KEY (`idvisita`) REFERENCES `visitas` (`id`),
  ADD CONSTRAINT `fk_segimientoarticulos_articulo` FOREIGN KEY (`idarticulo`) REFERENCES `Articulo` (`id`),
  ADD CONSTRAINT `fk_segimientoarticulos_estado` FOREIGN KEY (`idestado`) REFERENCES `estados` (`id`),
  ADD CONSTRAINT `fk_segimientoarticulos_contrato` FOREIGN KEY (`idcontrato`) REFERENCES `contratos` (`id`);


ALTER TABLE `archivovisitas`
  ADD CONSTRAINT `fk_archivovisitas_articulo` FOREIGN KEY (`idarticulo`) REFERENCES `Articulo` (`id`),
  ADD CONSTRAINT `fk_archivovisitas_visita` FOREIGN KEY (`idvisita`) REFERENCES `visitas` (`id`);


-- 0023.archivos
CREATE TABLE IF NOT EXISTS archivos (
	id 	    		INT NOT NULL AUTO_INCREMENT,
	nombre			varchar(1000) NOT NULL,
	extension 		varchar(100) NOT NULL,   
    path		 	varchar(100) not null,
    -- sed_id			int not null,
    usu_id 			BIGINT(30) UNSIGNED NOT NULL,
    fsubida			datetime default current_timestamp,
    tipo            varchar(100),
	PRIMARY KEY (id),
	-- FOREIGN KEY (sed_id) REFERENCES sed(id),
    FOREIGN KEY (usu_id) REFERENCES usu(id)
) ENGINE=InnoDB COMMENT = 'Archivos';

