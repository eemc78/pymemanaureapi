exports.guardar_archivo = function (pool, data, callback) {
    let { nombre, extension, path, usu_id, tipo } = data;

    try {
        pool.getConnection((err, conn) => {
            if (err) return callback(null, err);

            let sql = "INSERT INTO ?? (nombre, extension, path, usu_id, tipo) VALUES (?, ?, ?, ?, ?);";
            let params = ["archivos", nombre, extension, path, usu_id, tipo];
            let mysql = require("mysql");
            sql = mysql.format(sql, params);
            conn.query(sql, [nombre, extension, path, usu_id, tipo], (err, results, fields) => {
                conn.release();
                if (err) return callback(null, err);
                return callback(results);
            });
        });
    } catch (error) {
        return callback(null, error);
    }
};

exports.get_archivo = function (pool, data, callback) {
    let { id } = data;

    try {
        pool.getConnection((err, conn) => {
            if (err) return callback(null, err);

            let sql = "SELECT * FROM ?? WHERE id=?;";
            let params = ["archivos", id];
            let mysql = require("mysql");
            sql = mysql.format(sql, params);
            conn.query(sql, [id], (err, results, fields) => {
                conn.release();
                if (err) return callback(null, err);
                return callback(results);
            });
        });
    } catch (error) {
        return callback(null, error);
    }
}