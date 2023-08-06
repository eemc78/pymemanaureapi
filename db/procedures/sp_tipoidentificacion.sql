DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_tipoidentificacion`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_VALUE(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
	set @id := JSON_VALUE(@parametros,'$.id');
	set @tipoidentificacion := JSON_VALUE(@parametros,'$.tipoidentificacion');

    
    insert into tipoidentificacion (
        id ,
        tipoidentificacion 
      )
    select 
        @id, 
        @tipoidentificacion
    where not exists(select 1 from tipoidentificacion where id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from personas where tipoidentificacion=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from tipoidentificacion where id=@id
    and id not in (select coalesce(tipoidentificacion,'') from personas);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_VALUE(@parametros,'$.id');
    set @tipoidentificacion := JSON_VALUE(@parametros,'$.tipoidentificacion');
    
    update tipoidentificacion set  --
        tipoidentificacion  = @tipoidentificacion
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	set @id := JSON_VALUE(@parametros,'$.id');
	  select 
      id,
      tipoidentificacion 
    from tipoidentificacion   --
    where id = @id; 
  end if;
  
  if @metodo = 'consultartodas' then
	set @id := JSON_VALUE(@parametros,'$.id');
	  select 
      id value,
      tipoidentificacion label 
    from tipoidentificacion; 
  end if;
  

END $$
DELIMITER ;