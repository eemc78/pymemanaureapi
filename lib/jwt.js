var jwt = require("jsonwebtoken");
var _ = require("lodash");

exports.verifyJWTToken = function (token) {
  return new Promise((resolve, reject) => {
    jwt.verify(token, process.env.JWT_SECRET, (err, decodedToken) => {
      if (err || !decodedToken) {
        return reject(err);
      }

      resolve(decodedToken);
    });
  });
};

exports.createJWToken = function (details) {
  if (typeof details !== "object") {
    details = {};
  }

  if (!details.maxAge || typeof details.maxAge !== "number") {
    details.maxAge = process.env.JWT_MAXAGE || 3600;
  }

  details.sessionData = _.reduce(
    details.sessionData || {},
    (memo, val, key) => {
      if (typeof val !== "function" && key !== "password") {
        memo[key] = val;
      }
      return memo;
    },
    {}
  );

  let token = jwt.sign(
    {
      data: details.sessionData,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: details.maxAge,
      algorithm: process.env.JWT_ALGORITHM || "HS256",
    }
  );

  return token;
};
