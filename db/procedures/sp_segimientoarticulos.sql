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