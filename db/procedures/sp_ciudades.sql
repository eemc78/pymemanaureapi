DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_ciudades`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
	set @id := JSON_VALUE(@parametros,'$.id');
	set @ciudad := JSON_VALUE(@parametros,'$.ciudad');
	set @iddepartamento := JSON_VALUE(@parametros,'$.iddepartamento');

    
    insert into ciudades (
        id,
        ciudad ,
        iddepartamento
      )
    select 
        @id,
        @ciudad,
        @iddepartamento
    where not exists(select 1 from ciudades where ciudad=@ciudad and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from terceros where ciudad=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from personas where ciudad=@id) then
            select false as eliminar;
        else
            select true as eliminar;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from ciudades where id=@id
    and id not in (select coalesce(ciudad,-1) from terceros)
    and id not in (select coalesce(ciudad,-1) from personas)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_VALUE(@parametros,'$.id');
    set @ciudad := JSON_VALUE(@parametros,'$.ciudad');
	set @iddepartamento := JSON_VALUE(@parametros,'$.iddepartamento');
    
    update ciudades set  --
        ciudad = @ciudad ,
        iddepartamento = @iddepartamento
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      ciudades.id,
      ciudades.ciudad ,
      departamentos.id,
      departamentos.departamento
    from ciudades inner join departamentos on ciudades.iddepartamento = departamentos.id  --
    where ciudades.id = @id; 
  end if;
  

END $$
DELIMITER ;