DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_tipopersona`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @tipopersona := JSON_VALUE(@parametros,'$.tipopersona');
    
    insert into tipopersona (
      tipopersona 
      )
    select 
      @tipopersona
    where not exists(select 1 from tipopersona where tipopersona=@tipopersona and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from personas where idtipopersona=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from tipopersona where id=@id
    and id not in (select coalesce(idtipopersona,-1) from personas);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @tipopersona := JSON_VALUE(@parametros,'$.tipopersona');
    
    update tipopersona set  --
      tipopersona  = @tipopersona
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      tipopersona 
    from tipopersona   --
    where id = @id; 
  end if;
  

  if @metodo = 'consultartodas' then
	  select 
      id value,
      tipopersona label 
    from tipopersona;   --
  end if;
  

END $$
DELIMITER ;