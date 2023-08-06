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