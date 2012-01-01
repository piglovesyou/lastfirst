(function() {
  var User, crypto, https, md5, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require("underscore");
  https = require('https');
  crypto = require('crypto');
  md5 = function(str) {
    return crypto.createHash('md5').update(str).digest('hex');
  };
  /*
   Class for user.
  */
  User = (function() {
    User.prototype.socket = null;
    User.prototype.id = '';
    User.prototype.token = '';
    User.prototype.isValid_ = false;
    User.prototype.isValid = function() {
      return this.isValid_;
    };
    User.prototype.setValid = function(valid) {
      return this.isValid_ = valid;
    };
    function User(socket) {
      this.socket = socket;
    }
    User.prototype.setToken = function(token) {
      this.token = token;
    };
    User.prototype.validate = function(fn) {
      var options;
      if (!this.socket || !this.token) {
        return;
      }
      options = {
        host: 'www.googleapis.com',
        path: '/oauth2/v1/tokeninfo?access_token=' + this.token
      };
      return https.get(options, __bind(function(res) {
        return res.on('data', __bind(function(data) {
          var json;
          json = JSON.parse(data.toString());
          if (!json.error) {
            this.id = md5(json.user_id);
            this.isValid_ = true;
            this.socket.emit('validated nicely!', {
              userId: this.id
            });
            return fn();
          } else {
            return this.socket.emit('need login');
          }
        }, this));
      }, this));
    };
    return User;
  })();
  exports.User = User;
}).call(this);
