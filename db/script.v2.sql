ALTER TABLE `usu` DROP `avatar`;

CREATE TABLE IF NOT EXISTS archivos (
	id 	    		INT NOT NULL AUTO_INCREMENT,
	nombre			varchar(1000) NOT NULL,
	extension 	varchar(100) NOT NULL,   
  path		 	  varchar(100) not null,
  tipo		 	  varchar(200) not null,
  sed_id			int not null,
  usu_id 			BIGINT(30) UNSIGNED NOT NULL,
  fsubida			datetime default current_timestamp,
	PRIMARY KEY (id),
	FOREIGN KEY (sed_id) REFERENCES sed(id),
  FOREIGN KEY (usu_id) REFERENCES usu(id)
) ENGINE=InnoDB COMMENT = 'Archivos';

alter table usu add avatar int;

alter table usu add CONSTRAINT `fk_usu_avatar` FOREIGN KEY (`avatar`) REFERENCES archivos(id);