CREATE TABLE IF NOT EXISTS emp (
	id			int not null auto_increment,
  razonsocial	varchar(256) not null,
  nit			varchar(20) not null,
  dv 			smallint not null,
  activa		TINYINT(1) NOT NULL default 0, 
  primary key(id),
  unique(razonsocial,nit,dv)
) ENGINE=InnoDB COMMENT = 'Empresas';

