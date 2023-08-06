DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_contratodetalle`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_VALUE(text_json,'$.metodo') FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_EXTRACT(text_json,'$.parametros') from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id) ;
  
  if @metodo = 'nuevo_registro' then
    set @id             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idcontrato     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idcontrato'));
    set @idarticulo     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @estadoarticulo := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.estadoarticulo'));
    set @idgestor       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));
    set @observacion    := JSON_VALUE(@parametros,'$.observacion');

    
    insert into contratodetalle (
        idcontrato,
        idarticulo,
        estadoarticulo,
        idgestor,
        observacion 
      )
    select 
        @idcontrato,
        @idarticulo,
        @estadoarticulo,
        @idgestor,
        @observacion
    where not exists(select 1 from contratodetalle where idcontrato=@idcontrato and id=@id); --

  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    -- VALIDA LAS FK    
    -- if  exists(select 1 from personas where idcontratodetalle=@id) then
    --   select false as eliminar;
    -- else
        select true as eliminar;
    -- end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_VALUE(@parametros,'$.id');
    
    delete from contratodetalle where id=@id
    ;  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id             := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @idcontrato     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idcontrato'));
    set @idarticulo     := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idarticulo'));
    set @estadoarticulo := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.estadoarticulo'));
    set @idgestor       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.idgestor'));
    set @observacion    := JSON_VALUE(@parametros,'$.observacion');

    
    update contratodetalle set  --
        idcontrato      = @idcontrato ,
        idarticulo      = @idarticulo ,
        estadoarticulo  = @estadoarticulo ,
        idgestor        = @idgestor ,
        observacion     = @observacion 
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
        c.idcontrato,
        c.idarticulo,
        c.estadoarticulo,
        c.idgestor,
        c.observacion,
        Articulo.nombre,
        estados.estado,
        concat( personas.papellido , ' ' , personas.sapellido ,' ' , personas.pnombre , ' ' , personas.snombre ) nombregestor
    from contratodetalle  c 
            inner join Articulo on Articulo.id =c.idarticulo
            inner join estados on estados.id= c.estadoarticulo
            inner join personas on personas.id= c.idgestor--
    where c.id = @id; 
  end if;
  

END $$
DELIMITER ;

--

