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