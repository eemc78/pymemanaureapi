DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_dofa`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @debilidades   := JSON_VALUE(@parametros,'$.debilidades');
    set @fortalezas    := JSON_VALUE(@parametros,'$.fortalezas');
    set @oportunidades := JSON_VALUE(@parametros,'$.oportunidades');
    set @amenazas      := JSON_VALUE(@parametros,'$.amenazas');
    set @idvisita      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));

    
    insert into dofa (
        debilidades,
        fortalezas,
        oportunidades,
        amenazas,
        idvisita
      )
    select 
        @debilidades,
        @fortalezas,
        @oportunidades,
        @amenazas,
        @idvisita
    where not exists(select 1 from dofa where idvisita=@idvisita and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    -- if  exists(select 1 from terceros where iddofa=@id) then
    --   select false as eliminar;
    -- else
        select true as eliminar;
    -- end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from dofa where id=@id
    -- and id not in (select coalesce(iddofa,-1) from terceros)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @debilidades   := JSON_VALUE(@parametros,'$.debilidades');
    set @fortalezas    := JSON_VALUE(@parametros,'$.fortalezas');
    set @oportunidades := JSON_VALUE(@parametros,'$.oportunidades');
    set @amenazas      := JSON_VALUE(@parametros,'$.amenazas');
    set @idvisita      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idvisita'));

    update dofa set  --
        debilidades  = @debilidades ,
        fortalezas   = @fortalezas ,
        oportunidades= @oportunidades ,
        amenazas     = @amenazas ,
        idvisita     = @idvisita 
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        id,
        debilidades,
        fortalezas,
        oportunidades,
        amenazas,
        idvisita
    from dofa   --
    where id = @id; 
  end if;
  

END $$
DELIMITER ;