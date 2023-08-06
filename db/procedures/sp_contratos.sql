DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_contratos`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                    := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idtercero             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @referencianumero      := JSON_VALUE(@parametros,'$.referencianumero');
    set @fecha                 := JSON_VALUE(@parametros,'$.fecha');
    set @tipo                  := JSON_VALUE(@parametros,'$.tipo');
    set @idrepresentante       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @necesitacapacitacion  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.necesitacapacitacion'));
    set @detalle               := JSON_VALUE(@parametros,'$.detalle');

    
    insert into contratos (
        idtercero,
        referencianumero,
        fecha,
        tipo,
        idrepresentante,
        necesitacapacitacion,
        detalle
      )
    select 
        @idtercero,
        @referencianumero,
        @fecha,
        @tipo,
        @idrepresentante,
        @necesitacapacitacion,
        @detalle
    where not exists(select 1 from contratos where  id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from contratodetalle where idcontrato=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from segimientoarticulos where idcontrato=@id) then
            select false as eliminar;
        else
            select true as eliminar;
        end if;
        
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from contratos where id=@id
    and id not in (select coalesce(idcontrato,-1) from contratodetalle)
    and id not in (select coalesce(idcontrato,-1) from segimientoarticulos)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                    := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idtercero             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @referencianumero      := JSON_VALUE(@parametros,'$.referencianumero');
    set @fecha                 := JSON_VALUE(@parametros,'$.fecha');
    set @tipo                  := JSON_VALUE(@parametros,'$.tipo');
    set @idrepresentante       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @necesitacapacitacion  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.necesitacapacitacion'));
    set @detalle               := JSON_VALUE(@parametros,'$.detalle');
    
    update contratos set  --
        idtercero             = @idtercero,
        referencianumero      = @referencianumero,
        fecha                 = @fecha,
        tipo                  = @tipo,
        idrepresentante       = @idrepresentante,
        necesitacapacitacion  = @necesitacapacitacion,
        detalle               = @detalle
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        c.id,
        c.idtercero,
        c.referencianumero,
        c.fecha,
        c.tipo,
        c.idrepresentante,
        c.necesitacapacitacion,
        c.detalle,
        concat( personas.papellido , ' ' , personas.sapellido ,' ' , personas.pnombre , ' ' , personas.snombre ) nombrerepresentante
    from contratos c
            inner join  personas  on c.idrepresentante =personas.id --
    where c.id=@id; 
  end if;
  

END $$
DELIMITER ;