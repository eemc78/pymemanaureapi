DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_visitas`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id                            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @fecha                         := JSON_VALUE(@parametros,'$.fecha');
    set @idtercero                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @idpersona                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idpersona'));
    set @renovomatricula               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.renovomatricula'));
    set @fecharenovacion               := JSON_VALUE(@parametros,'$.fecharenovacion');
    set @direccionactual               := JSON_VALUE(@parametros,'$.direccionactual');
    set @telefonoactual                := JSON_VALUE(@parametros,'$.telefonoactual');
    set @emailactual                   := JSON_VALUE(@parametros,'$.emailactual');
    set @generonuevosempleos           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.generonuevosempleos'));
    set @cuantosempleosformales        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosformales'));
    set @cuantosempleosinformales      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosinformales'));
    set @capemprendimiento             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capemprendimiento'));
    set @capcontabilidad               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capcontabilidad'));
    set @capsistemas                   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capsistemas'));
    set @capmarketing                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capmarketing'));
    set @capotros                      := JSON_VALUE(@parametros,'$.capotros');
    set @idarchivo                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarchivo'));
    set @idestadolocativa              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idestadolocativa'));
    set @descripcionlocativa           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.descripcionlocativa'));
    set @descripcionimpacto            := JSON_VALUE(@parametros,'$.descripcionimpacto');
    set @incrementoventas              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.incrementoventas'));
    set @iniciotramitecc               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.iniciotramitecc'));
    set @razonnotramitecc              := JSON_VALUE(@parametros,'$.razonnotramitecc');
    set @observacionesgestor           := JSON_VALUE(@parametros,'$.observacionesgestor');
    set @observacionesmicroempresario  := JSON_VALUE(@parametros,'$.observacionesmicroempresario');
    set @idrepresentante               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idgestor                      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));

    
    insert into visitas (
        fecha,
        idtercero,
        idpersona,
        renovomatricula,
        fecharenovacion,
        direccionactual,
        telefonoactual,
        emailactual,
        generonuevosempleos,
        cuantosempleosformales,
        cuantosempleosinformales,
        capemprendimiento,
        capcontabilidad,
        capsistemas,
        capmarketing,
        capotros,
        idarchivo,
        idestadolocativa,
        descripcionlocativa,
        descripcionimpacto,
        incrementoventas,
        iniciotramitecc,
        razonnotramitecc,
        observacionesgestor,
        observacionesmicroempresario,
        idrepresentante,
        idgestor
      )
    select 
        @fecha,
        @idtercero,
        @idpersona,
        @renovomatricula,
        @fecharenovacion,
        @direccionactual,
        @telefonoactual,
        @emailactual,
        @generonuevosempleos,
        @cuantosempleosformales,
        @cuantosempleosinformales,
        @capemprendimiento,
        @capcontabilidad,
        @capsistemas,
        @capmarketing,
        @capotros,
        @idarchivo,
        @idestadolocativa,
        @descripcionlocativa,
        @descripcionimpacto,
        @incrementoventas,
        @iniciotramitecc,
        @razonnotramitecc,
        @observacionesgestor,
        @observacionesmicroempresario,
        @idrepresentante,
        @idgestor
    where not exists(select 1 from visitas where fecha=@fecha and idtercero=@idtercero and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');

    -- VALIDA LAS FK    
    if  exists(select 1 from archivovisitas where idvisitas=@id) then
      select false as eliminar;
    else
        if  exists(select 1 from dofa where idvisitas=@id) then
            select false as eliminar;
        else
            if  exists(select 1 from segimientoarticulos where idvisitas=@id) then
                select false as eliminar;
            else
                select true as eliminar;
            end if;
        end if;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from visitas where id=@id
    and id not in (select coalesce(idvisitas,-1) from archivovisitas)
    and id not in (select coalesce(idvisitas,-1) from dofa)
    and id not in (select coalesce(idvisitas,-1) from segimientoarticulos)
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id                            := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @fecha                         := JSON_VALUE(@parametros,'$.fecha');
    set @idtercero                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idtercero'));
    set @idpersona                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idpersona'));
    set @renovomatricula               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.renovomatricula'));
    set @fecharenovacion               := JSON_VALUE(@parametros,'$.fecharenovacion');
    set @direccionactual               := JSON_VALUE(@parametros,'$.direccionactual');
    set @telefonoactual                := JSON_VALUE(@parametros,'$.telefonoactual');
    set @emailactual                   := JSON_VALUE(@parametros,'$.emailactual');
    set @generonuevosempleos           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.generonuevosempleos'));
    set @cuantosempleosformales        := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosformales'));
    set @cuantosempleosinformales      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cuantosempleosinformales'));
    set @capemprendimiento             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capemprendimiento'));
    set @capcontabilidad               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capcontabilidad'));
    set @capsistemas                   := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capsistemas'));
    set @capmarketing                  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.capmarketing'));
    set @capotros                      := JSON_VALUE(@parametros,'$.capotros');
    set @idarchivo                     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarchivo'));
    set @idestadolocativa              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idestadolocativa'));
    set @descripcionlocativa           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.descripcionlocativa'));
    set @descripcionimpacto            := JSON_VALUE(@parametros,'$.descripcionimpacto');
    set @incrementoventas              := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.incrementoventas'));
    set @iniciotramitecc               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.iniciotramitecc'));
    set @razonnotramitecc              := JSON_VALUE(@parametros,'$.razonnotramitecc');
    set @observacionesgestor           := JSON_VALUE(@parametros,'$.observacionesgestor');
    set @observacionesmicroempresario  := JSON_VALUE(@parametros,'$.observacionesmicroempresario');
    set @idrepresentante               := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idrepresentante'));
    set @idgestor                      := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));
    
    update visitas set  --
        fecha                           = @fecha,
        idtercero                       = @idtercero,
        idpersona                       = @idpersona,
        renovomatricula                 = @renovomatricula,
        fecharenovacion                 = @fecharenovacion,
        direccionactual                 = @direccionactual,
        telefonoactual                  = @telefonoactual,
        emailactual                     = @emailactual,
        generonuevosempleos             = @generonuevosempleos,
        cuantosempleosformales          = @cuantosempleosformales,
        cuantosempleosinformales        = @cuantosempleosinformales,
        capemprendimiento               = @capemprendimiento,
        capcontabilidad                 = @capcontabilidad,
        capsistemas                     = @capsistemas,
        capmarketing                    = @capmarketing,
        capotros                        = @capotros,
        idarchivo                       = @idarchivo,
        idestadolocativa                = @idestadolocativa,
        descripcionlocativa             = @descripcionlocativa,
        descripcionimpacto              = @descripcionimpacto,
        incrementoventas                = @incrementoventas,
        iniciotramitecc                 = @iniciotramitecc,
        razonnotramitecc                = @razonnotramitecc,
        observacionesgestor             = @observacionesgestor,
        observacionesmicroempresario    = @observacionesmicroempresario,
        idrepresentante                 = @idrepresentante,
        idgestor                        = @idgestor
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        v.fecha,
        v.idtercero,
        v.idpersona,
        v.renovomatricula,
        v.fecharenovacion,
        v.direccionactual,
        v.telefonoactual,
        v.emailactual,
        v.generonuevosempleos,
        v.cuantosempleosformales,
        v.cuantosempleosinformales,
        v.capemprendimiento,
        v.capcontabilidad,
        v.capsistemas,
        v.capmarketing,
        v.capotros,
        v.idarchivo,
        v.idestadolocativa,
        v.descripcionlocativa,
        v.descripcionimpacto,
        v.incrementoventas,
        v.iniciotramitecc,
        v.razonnotramitecc,
        v.observacionesgestor,
        v.observacionesmicroempresario,
        v.idrepresentante,
        v.idgestor,
        terceros.razonsocial,
        terceros.NIT,
        concat( personas.papellido , ' ' , personas.sapellido ,' ' , personas.pnombre , ' ' , personas.snombre ) nombrepersona,
        concat( representante.papellido , ' ' , representante.sapellido ,' ' , representante.pnombre , ' ' , representante.snombre ) nombrerepresentante,
        concat( gestor.papellido , ' ' , gestor.sapellido ,' ' , gestor.pnombre , ' ' , gestor.snombre ) nombregestor


    from visitas v 
            inner join terceros on v.idtercero = terceros.id
            inner join personas on v.idpersonas = personas.id
            inner join personas representante on v.idpersona = representante.id  --
            inner join personas gestor on v.idpersona = gestor.id  --
            inner join estados on v.idestadolocativas = estados.id
             --
    where v.id = @id; 
  end if;
  

END $$
DELIMITER ;