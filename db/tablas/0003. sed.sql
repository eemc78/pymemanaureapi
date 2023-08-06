CREATE TABLE IF NOT EXISTS sed (
	id			int not null auto_increment,
  denominacion varchar(256) not null,
  activa		TINYINT(1) NOT NULL default 0, 
  emp_id		INT NOT NULL,
  primary key(id),
  FOREIGN KEY (`emp_id`) REFERENCES emp(id),
  unique(denominacion,emp_id)
) ENGINE=InnoDB COMMENT = 'Sedes';