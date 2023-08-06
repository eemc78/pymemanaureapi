DELIMITER $$
CREATE OR REPLACE PROCEDURE `sp_sed`(IN js_id int)
BEGIN
  SET @metodo     = '';
  SET @metodo     = (SELECT JSON_UNQUOTE(JSON_EXTRACT(text_json,'$.metodo')) FROM api WHERE id=js_id);
  SET @parametros = (SELECT JSON_UNQUOTE(JSON_EXTRACT(text_json,'$.parametros')) from api where id=js_id);
  set @usuario_id = (select usuario_id from api where id=js_id);
  
  if @metodo = 'nuevo_registro' then
	  set @denominacion := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.denominacion'));
    set @activa       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.activa'));
    set @emp_id       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.emp_id'));
    set @csecundario  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.csecundario'));
    set @cprimario    := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cprimario'));
    
    insert into sed (
      denominacion,
      activa,
      emp_id,
      colorp,
      colors )
    select 
      @denominacion,
      @activa,
      @emp_id,
      @cprimario,
      @csecundario
    where not exists(select 1 from sed where denominacion=@denominacion and id=@id);
  end if;
  
  if @metodo = 'permiso_eliminar' then
    set @id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    
    -- VALIDA LAS FK
    if  exists(select 1 from usu where sed_id=@id) then
      select false as eliminar;
    else
      select true as eliminar;
    end if;
  
  end if;

  if @metodo = 'eliminar_registro' then
    set @id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    
    delete from sed where id=@id
    and id not in (select coalesce(sed_id,-1) from usu);  -- QUE NO TENGA FK RELACIONADO
  end if;

  if @metodo = 'editar_registro' then
    set @id           := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.id'));
    set @denominacion := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.denominacion'));
    set @activa       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.activa'));
    set @emp_id       := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.emp_id'));
    set @csecundario  := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.csecundario'));
    set @cprimario    := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.cprimario'));
    
    update sed set 
      denominacion  = @denominacion, 
      activa        = @activa, 
      emp_id        = @emp_id, 
      colorp        = @cprimario, 
      colors        = @csecundario  
    where id = @id;
  end if;
  
  if @metodo = 'consultar' then
	  select 
      id,
      denominacion,
      activa,
      emp_id,
      colorp,
      colors 
    from sed where activa = 1;
  end if;
  
  if @metodo = 'consultar_usuario' then
    set @usu_id := JSON_UNQUOTE(JSON_EXTRACT(@parametros,'$.usu_id'));
	  select 
      sed.id, 
      denominacion, 
      activa, 
      emp_id, 
      colorp, 
      colors 
    from sed
    inner join sedxusu on sedxusu.sed_id = sed.id -- select sed_id, usu_id from sedxusu;
    where sedxusu.usu_id = @usu_id and activa = 1;
  end if;

END $$
DELIMITER ;