DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_personas`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @pnombre             := JSON_VALUE(@parametros,'$.pnombre');
    set @snombre             := JSON_VALUE(@parametros,'$.snombre');
    set @papellido           := JSON_VALUE(@parametros,'$.papellido');
    set @sapellido           := JSON_VALUE(@parametros,'$.sapellido');
    set @idtipopersona       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtipopersona'));
    set @sexo                := JSON_VALUE(@parametros,'$.sexo');
    set @edad                := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.edad'));
    set @direccion           := JSON_VALUE(@parametros,'$.direccion');
    set @telefonocel         := JSON_VALUE(@parametros,'$.telefonocel');
    set @email               := JSON_VALUE(@parametros,'$.email');
    set @tipoidentificacion  := JSON_VALUE(@parametros,'$.tipoidentificacion');
    set @noidentificacion    := JSON_VALUE(@parametros,'$.noidentificacion');
    set @ciudad              := JSON_VALUE(@parametros,'$.ciudad');
    set @usuario             := JSON_VALUE(@parametros,'$.usuario');
    set @clave               := JSON_VALUE(@parametros,'$.clave');

    
    insert into personas (
        pnombre,
        snombre,
        papellido,
        sapellido,
        idtipopersona,
        sexo,
        edad,
        direccion,
        telefonocel,
        email,
        tipoidentificacion,
        noidentificacion,
        ciudad,
        usuario,
        clave
      )
    select 
        @pnombre,
        @snombre,
        @papellido,
        @sapellido,
        @idtipopersona,
        @sexo,
        @edad,
        @direccion,
        @telefonocel,
        @email,
        @tipoidentificacion,
        @noidentificacion,
        @ciudad,
        @usuario,
        @clave
    where not exists(select 1 from personas where noidentificacion=@noidentificacion ); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from terceros where @id = idrepresentante ) then
      select false as eliminar;
    else
        if  exists(select 1 from visitas where @id in ( idpersona, idrepresentante , idgestor )) then
            select false as eliminar;
        else
            if  exists(select 1 from contratodetalle where @id = idgestor ) then
                select false as eliminar;
            else
                if  exists(select 1 from contratos where @id = idrepresentante ) then
                    select false as eliminar;
                else
                    select true as eliminar;
                end if;
            end if;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from personas where id=@id
    and id not in (select coalesce(idrepresentante,-1) from contratos)
    and id not in (select coalesce(idrepresentante,-1) from terceros)
    and id not in (select coalesce(idrepresentante,-1) from visitas)
    and id not in (select coalesce(idpersona,-1) from visitas)
    and id not in (select coalesce(idgestor,-1) from visitas)
    and id not in (select coalesce(idgestor,-1) from contratodetalle)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @pnombre             := JSON_VALUE(@parametros,'$.pnombre');
    set @snombre             := JSON_VALUE(@parametros,'$.snombre');
    set @papellido           := JSON_VALUE(@parametros,'$.papellido');
    set @sapellido           := JSON_VALUE(@parametros,'$.sapellido');
    set @idtipopersona       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtipopersona'));
    set @sexo                := JSON_VALUE(@parametros,'$.sexo');
    set @edad                := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.edad'));
    set @direccion           := JSON_VALUE(@parametros,'$.direccion');
    set @telefonocel         := JSON_VALUE(@parametros,'$.telefonocel');
    set @email               := JSON_VALUE(@parametros,'$.email');
    set @tipoidentificacion  := JSON_VALUE(@parametros,'$.tipoidentificacion');
    set @noidentificacion    := JSON_VALUE(@parametros,'$.noidentificacion');
    set @ciudad              := JSON_VALUE(@parametros,'$.ciudad');
    set @usuario             := JSON_VALUE(@parametros,'$.usuario');
    set @clave               := JSON_VALUE(@parametros,'$.clave');
    
    update personas set  --
        pnombre             =   @pnombre,
        snombre             =   @snombre,
        papellido           =   @papellido,
        sapellido           =   @sapellido,
        idtipopersona       =   @idtipopersona,
        sexo                =   @sexo,
        edad                =   @edad,
        direccion           =   @direccion,
        telefonocel         =   @telefonocel,
        email               =   @email,
        tipoidentificacion  =   @tipoidentificacion,
        noidentificacion    =   @noidentificacion,
        ciudad              =   @ciudad,
        usuario             =   @usuario,
        clave               =   @clave
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        personas.pnombre,
        personas.snombre,
        personas.papellido,
        personas.sapellido,
        personas.idtipopersona,
        personas.sexo,
        personas.edad,
        personas.direccion,
        personas.telefonocel,
        personas.email,
        personas.tipoidentificacion,
        personas.noidentificacion,
        personas.ciudad,
        personas.usuario,
        personas.clave,
        tipopersona.tipopersona,
        tipoidentificacion.tipoidentificacion,
        ciudades.ciudad
    from personas 
        inner join tipopersona on personas.idtipopersona = tipopersona.id  --
        inner join tipoidentificacion on personas.tipoidentificacion= tipoidentificacion.id  --
        inner join ciudades on personas.ciudad= ciudades.id  --
    where personas.id = @id; 
  end if;
  

END $$
DELIMITER ;