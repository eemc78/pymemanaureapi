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

    -- VALIDA LAS FK
    if exists(select 1 from usu where grupo_id=@id) then
      select false as elimininar;
    else
      select true as eliminar;
	  end if;

  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from grupo where id=@id
    and id not in (select coalesce(grupo_id,-1) from usu);  -- QUE NO TENGA FK RELACIONADO
  end if;
  
  if @metodo = 'editar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    set @nombre := JSON_VALUE(@parametros,'$.nombre');
    set @activo := JSON_VALUE(@parametros,'$.activo');
    
    update grupo set nombre=@nombre, activo=@activo
    where id=@id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      nombre 
    from grupo   --
    where id = @id; 
  end if;
  
  if @metodo = 'consultartodas' then
	  select 
      id value,
      nombre label
    from grupo; 
  end if;
  
END $$
DELIMITER ;