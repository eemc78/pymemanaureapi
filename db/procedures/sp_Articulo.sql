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