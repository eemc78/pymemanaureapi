DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_clasepersona`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @clasepersona := JSON_VALUE(@parametros,'$.clasepersona');
    
    insert into clasepersona (
      clasepersona 
      )
    select 
      @clasepersona
    where not exists(select 1 from clasepersona where clasepersona=@clasepersona and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from terceros where idclasepersona=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from clasepersona where id=@id
    and id not in (select coalesce(idclasepersona,-1) from terceros);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @clasepersona := JSON_VALUE(@parametros,'$.clasepersona');
    
    update clasepersona set  --
      clasepersona  = @clasepersona
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      clasepersona 
    from clasepersona   --
    where id = @id; 
  end if;
  
  if @metodo = 'consultartodas' then
	  select 
      id value,
      clasepersona label 
    from clasepersona   --
  end if;
  

END $$
DELIMITER ;