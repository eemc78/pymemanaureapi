exports.login = (pool, args, cb) => {
  let { usuario, clave } = args;
  pool.getConnection((err, conn) => {
    if (err) return res.status(500).json({ res: "ko", error: err });
    pool.query("select u.id, usuario, u.activo, u.nombres, u.apellidos, g.nombre as grupo, u.avatar,u.sed_id, s.denominacion as sede from usu u inner join grupo g on g.id = u.grupo_id left join sed s on s.id=u.sed_id WHERE usuario = ? AND clave = MD5(?)", [usuario, clave], (err, results, fields) => {
      conn.release();
      if (err) return cb(null, err);
      return cb(results);
    });
  })
}

exports.perfil = (pool, args, cb) => {
  pool.getConnection((err, conn) => {
    if (err) return res.status(500).json({ res: "ko", error: err });
    let sql = "UPDATE usu SET nombres=?, apellidos=?";
    let params = [args.nombres, args.apellidos];
    if (args.clave) {
      sql += ", clave=MD5(?)";
      params.push(args.clave);
    }
    if (args.avatar) {
      // sql += ", avatar=decode(?, 'base64')";
      sql += ", avatar=?";
      params.push(args.avatar);
    }

    sql += " WHERE id=?";

    params.push(args.id);

    pool.query(sql, params, (err, results, fields) => {
      conn.release();
      if (err) return cb(null, err);
      return cb(results);
    });
  })
}
