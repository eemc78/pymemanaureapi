require("dotenv").config();
var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var mysql = require('mysql2');
var cors = require("cors");
var fileUpload = require("express-fileupload");
var bodyParser = require("body-parser");


var indexRouter = require('./routes/index');
// var usersRouter = require('./routes/users');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(cors());
app.use(fileUpload());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

//#region middleware para validar el token
let rutasExcluidas = [ // Incluir asquí todas las rutas que no requieren token
  "/api/usuario/login",
]

app.use((req, res, next) => {
  let url = req.originalUrl;
  if (url.indexOf("/api/") >= 0) {
    let rutaProtegida = true;

    if(rutasExcluidas.indexOf(url)>=0) rutaProtegida = false;

    if (rutaProtegida) {
      if (req.headers && req.headers.authorization && req.headers.authorization.split(' ')[0] === 'Bearer') {
        let token = req.headers.authorization.split(' ')[1];

        if (!token || token === 'null' || token === '') return res.status(401).json({ res: "ko", error: "No autorizado!", success: false, logout: true });

        const { verifyJWTToken, createJWToken } = require("./lib/jwt");
        verifyJWTToken(token)
          .then(decode => {
            req.user = decode.data;
            req.token = createJWToken({ sessionData: decode.data })
            next();
          }).catch(err => {
            console.log("🚀 ~ file: app.js:52 ~ app.use ~ err:", err)
            res.status(401).json({ res: "ko", error: err, success: false, logout: true });
          })
      } else {
        res.status(401).json({ res: "ko", error: "No autorizado!", success: false, logout: true });
      }
    } else {
      next();
    }
  } else {
    next();
  }
})
//#endregion

//#region Pool de Conexion
var pool = mysql.createPool({
  connectionLimit: 10,
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});

// Incluir el pool en el request
app.use((req, res, next) => {
  req.pool = pool;
  next();
});
//#endregion


app.use('/', indexRouter);
// app.use('/users', usersRouter);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
  next(createError(404));
});

// error handler
app.use(function (err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});



// app.listen(process.env.SERVER_PORT, () => {
//   console.log(`Server running on port ${process.env.SERVER_PORT}`);
// });

// Pruebas de conexion
try {
  pool.getConnection((err, conn) => {
    if (err) return console.error(err);
    console.log('Connected to database');
    pool.query('SELECT 1 + 1 AS solution', (error, results, fields) => {
      conn.release();
      if (error) return console.error(error);
      console.log('La solución a la suma es: ', results[0].solution, '- esto demuestra que la conexión a la base de datos funciona correctamente.');
    });
  })
} catch (error) {
  console.error('Unable to connect to the database:', error);
}

module.exports = app;
