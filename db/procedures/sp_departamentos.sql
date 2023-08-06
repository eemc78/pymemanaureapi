DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_departamentos`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
	set @id := JSON_VALUE(@parametros,'$.id');
	set @departamento := JSON_VALUE(@parametros,'$.departamento');

    
    insert into departamentos (
      id,
      departamento 
      )
    select 
      @id,
      @departamento
    where not exists(select 1 from departamentos where departamento=@departamento and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from ciudades where iddepartamento=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from departamentos where id=@id
    and id not in (select coalesce(iddepartamento,-1) from ciudades);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_VALUE(@parametros,'$.id');
    set @departamento := JSON_VALUE(@parametros,'$.departamento');
    
    update departamentos set  --
      id            = @id,
      departamento  = @departamento
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      departamento 
    from departamentos   --
    where id = @id; 
  end if;
  
  if @metodo = 'consultartodas' then
	  select 
      id value,
      departamento label
    from departamentos; 
  end if;
  

END $$
DELIMITER ;