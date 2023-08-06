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