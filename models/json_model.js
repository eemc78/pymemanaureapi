exports.procesar_json = (pool, params, usuario_id, cb) => {
  pool.getConnection((err, conn) => {
    if (err) return cb(null, err);
    conn.query(
      "insert into ?? (text_json, usuario_id) values (?, ?)", ['api', JSON.stringify(params), usuario_id], (err, res, fields) => {
        if (err) {
          conn.release();
          return cb(null, err);
        }
        conn.query(`call sp_${params.modelo.toLowerCase()}(?)`, res.insertId, (err, results, fields) => {
          conn.release();
          if (err) return cb(null, err);
          return cb(results[0], null);
        });
      });
  })
}