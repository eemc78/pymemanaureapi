function totalCountToString(params) {
  var query = "select count(*) as totalCount from ?? ";
  // if (params.join && params.join !== '') {
  //   query += ` ${params.join} `
  // }
  if(params.join?.length>0){
    query += params.join.join(' ');
  }
  query += ' where 1=1 '
  if (params.where) {
    query += ' and ' + params.where
  }
  if (params.filter && params.filter !== '') {
    var filtroConstruido = ''
    filtroConstruido += ' and ( '
    let columnas = params.columnsFilter ? params.columnsFilter : params.columns
    columnas.forEach(el => {
      var column = el
      if (column.indexOf(' as ') !== -1) {
        column = column.substring(0, column.indexOf(' as '))
      }
      filtroConstruido += column + ` like '%${params.filter}%' or `
    });
    filtroConstruido = filtroConstruido.substring(0, filtroConstruido.length - 3)
    filtroConstruido += ' ) '

    query += ` ${filtroConstruido} `
  }
  return query;
}

exports.select = (pool, params, usuario_id, cb) => {
  let { table, start, limit, orderBy, descending, join, columns, columnsFilter, filter, where } = params;
  if (start) start = 1;
  if (limit) limit = 10;

  pool.getConnection((err, conn) => {
    if (err) return res.status(500).json({ res: "ko", error: err });
    var query = totalCountToString(params)
    let mysql = require("mysql");
    query = mysql.format(query, table);

    pool.query(query, (err, results, fields) => {
      if (err) {
        conn.release();
        return cb(null, err);
      }

      var totalCount = results[0].totalCount;

      query = "select ";
      if (columns && columns.length > 0) query += columns.map(el => el).join(', ')
      else query += ' * '
      query += " from ??";
      //join
      // if (join && join !== '') {
      //   query += ` ${join} `
      // }
      if(params.join?.length>0){
        query += params.join.join(' ');
      }
      query += ' where 1=1 '
      if (where) {
        query += ' and ' + where
      }

      if (filter && filter !== '') {
        var filtroConstruido = ''
        filtroConstruido += ' and ( '
        let columnas = columnsFilter?.length > 0 ? columnsFilter : columns
        columnas.forEach(el => {
          var column = el
          if (column.indexOf(' as ') !== -1) {
            column = column.substring(0, column.indexOf(' as '))
          }
          // lower filter
          filter = filter.toLowerCase()
          filtroConstruido += ` lower(${column}) like '%${filter}%' or `
        });
        filtroConstruido = filtroConstruido.substring(0, filtroConstruido.length - 3)
        filtroConstruido += ' ) '

        query += ` ${filtroConstruido} `
      }

      //orderBy
      if (orderBy && orderBy !== '') {
        query += ` ORDER BY ${orderBy} ${descending ? 'DESC' : ''}`;
      }
      query += " limit ? OFFSET ?";
      var _table = [table, limit, start];

      query = mysql.format(query, _table);


      pool.query(`insert into ?? (sql_command,usuario_id) values (?,?)`, ['api', query, usuario_id ], (err) => {
        if (err) {
          conn.release();
          return cb(null, err);
        }
        pool.query(query, (err, results, fields) => {
          conn.release();
          if (err) return cb(null, err);
          return cb({
            totalCount: totalCount,
            results: results
          });
        });
      })


      // return cb(results);
    });

    // return cb({
    //   table: table,
    //   start: start,
    //   limit: limit,
    //   orderBy: orderBy,
    //   descending: descending,
    //   join: join,
    //   columns: columns,
    //   columnsFilter: columnsFilter,
    //   filter: filter,
    //   where: where
    // })



  })
}