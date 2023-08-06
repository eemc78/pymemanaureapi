

module.exports = (router) => {
  router.post('/api/json/', (req, res, next) => {
    const usuario_id = req.user?.id;
    const { procesar_json } = require("../models/json_model");
    procesar_json(req.pool, req.body, usuario_id, (results, err) => {
      if (err) return res.status(500).json({ res: "ko", error: err });
      return res.json({
        res: "ok",
        result: results,
        token: req.token
      });
    })
  });

  // router.use('/api/json', router);
}