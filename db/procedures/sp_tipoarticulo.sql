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