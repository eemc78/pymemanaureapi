DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_terceros`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @NIT                       := JSON_VALUE(@parametros,'$.NIT');
    set @razonsocial               := JSON_VALUE(@parametros,'$.razonsocial');
    set @registradoencc            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.registradoencc'));
    set @matriculaencc             := JSON_VALUE(@parametros,'$.matriculaencc');
    set @fechaconstitucion         := JSON_VALUE(@parametros,'$.fechaconstitucion');
    set @tipocontribuyente         := JSON_VALUE(@parametros,'$.tipocontribuyente');
    set @ciudad                    := JSON_VALUE(@parametros,'$.ciudad');
    set @telefonocel               := JSON_VALUE(@parametros,'$.telefonocel');
    set @email                     := JSON_VALUE(@parametros,'$.email');
    set @direccion                 := JSON_VALUE(@parametros,'$.direccion');
    set @telefonofijo              := JSON_VALUE(@parametros,'$.telefonofijo');
    set @idrepresentante           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idsector                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idsector'));
    set @cantidadempleosformales   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosformales'));
    set @cantidadempleosinformales := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosinformales'));
    set @idclasepersona            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idclasepersona'));

    insert into terceros (
        NIT,
        razonsocial,
        registradoencc,
        matriculaencc,
        fechaconstitucion,
        tipocontribuyente,
        ciudad,
        telefonocel,
        email,
        direccion,
        telefonofijo,
        idrepresentante,
        idsector,
        cantidadempleosformales,
        cantidadempleosinformales,
        idclasepersona
      )
    select 
        @NIT,
        @razonsocial,
        @registradoencc,
        @matriculaencc,
        @fechaconstitucion,
        @tipocontribuyente,
        @ciudad,
        @telefonocel,
        @email,
        @direccion,
        @telefonofijo,
        @idrepresentante,
        @idsector,
        @cantidadempleosformales,
        @cantidadempleosinformales,
        @idclasepersona
    where not exists(select 1 from terceros where NIT=NIT and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    if  exists(select 1 from contratos where id=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from visitas where id=@id) then
            select false as eliminar;
        else
            select true as eliminar;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from terceros where id=@id
    and id not in (select coalesce(id,-1) from contratos)
    and id not in (select coalesce(id,-1) from visitas)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @NIT                       := JSON_VALUE(@parametros,'$.NIT');
    set @razonsocial               := JSON_VALUE(@parametros,'$.razonsocial');
    set @registradoencc            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.registradoencc'));
    set @matriculaencc             := JSON_VALUE(@parametros,'$.matriculaencc');
    set @fechaconstitucion         := JSON_VALUE(@parametros,'$.fechaconstitucion');
    set @tipocontribuyente         := JSON_VALUE(@parametros,'$.tipocontribuyente');
    set @ciudad                    := JSON_VALUE(@parametros,'$.ciudad');
    set @telefonocel               := JSON_VALUE(@parametros,'$.telefonocel');
    set @email                     := JSON_VALUE(@parametros,'$.email');
    set @direccion                 := JSON_VALUE(@parametros,'$.direccion');
    set @telefonofijo              := JSON_VALUE(@parametros,'$.telefonofijo');
    set @idrepresentante           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idsector                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idsector'));
    set @cantidadempleosformales   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosformales'));
    set @cantidadempleosinformales := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cantidadempleosinformales'));
    set @idclasepersona            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idclasepersona'));
    
    update terceros set  --
        NIT                       = @NIT ,
        razonsocial               = @razonsocial ,
        registradoencc            = @registradoencc ,
        matriculaencc             = @matriculaencc ,
        fechaconstitucion         = @fechaconstitucion ,
        tipocontribuyente         = @tipocontribuyente ,
        ciudad                    = @ciudad ,
        telefonocel               = @telefonocel ,
        email                     = @email ,
        direccion                 = @direccion ,
        telefonofijo              = @telefonofijo ,
        idrepresentante           = @idrepresentante ,
        idsector                  = @idsector ,
        cantidadempleosformales   = @cantidadempleosformales ,
        cantidadempleosinformales = @cantidadempleosinformales ,
        idclasepersona            = @idclasepersona 
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        t.NIT,
        t.razonsocial,
        t.registradoencc,
        t.matriculaencc,
        t.fechaconstitucion,
        t.tipocontribuyente,
        t.ciudad,
        t.telefonocel,
        t.email,
        t.direccion,
        t.telefonofijo,
        t.idrepresentante,
        t.idsector,
        t.cantidadempleosformales,
        t.cantidadempleosinformales,
        t.idclasepersona,
        ciudades.ciudad,
        concat(p.papellido, ' ' , p.sapellido , ' ' , p.pnombre, ' ', p.snombre ) as nombrepersona,
        concat(representante.papellido, ' ' , representante.sapellido , ' ' , representante.pnombre, ' ', representante.snombre ) as nombrerepresentante,
        concat(gestor.papellido, ' ' , gestor.sapellido , ' ' , gestor.pnombre, ' ', gestor.snombre ) as nombregestor

    from terceros t
        inner join ciudades on t.ciudad = ciudades.id  --
        inner join personas p on t.idpersona = p.id  --
        inner join personas representante on t.idpersona = representante.id  --
        inner join personas gestor on t.idpersona = gestor.id  --
    where t.id = @id; 
  end if;
  

END $$
DELIMITER ;