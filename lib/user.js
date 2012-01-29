var NO_AUTH_FOR_DEV, SECRET, User, crypto, https, md5, updateWords, users, _;

SECRET = require('secret-strings').LAST_FIRST;

NO_AUTH_FOR_DEV = !SECRET.IS_PRODUCTION && SECRET.NO_AUTH_FOR_DEV;

_ = require("underscore");

https = require('https');

crypto = require('crypto');

md5 = function(str) {
  return crypto.createHash('md5').update(str).digest('hex');
};

updateWords = require('./socket_util').updateWords;

users = require('./users').getInstance();

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

  User.prototype.updateWords_ = function() {
    return updateWords(this.socket);
  };

  User.prototype.validateOK_ = function(id) {
    this.id = id;
    this.isValid_ = true;
    users.add(this);
    this.socket.emit('validated nicely!', {
      userId: this.id
    });
    return this.updateWords_();
  };

  function User(socket) {
    this.socket = socket;
    if (!this.socket) return false;
    this.updateWords_();
    if (NO_AUTH_FOR_DEV) {
      console.log('\nNO_AUTH_FOR_DEV......!!!!!\n');
      this.validateOK_('dummy_account');
    }
  }

  User.prototype.setToken = function(token) {
    this.token = token;
  };

  User.prototype.validate = function(fn) {
    var options;
    var _this = this;
    if (!this.socket || !this.token) return;
    options = {
      host: 'www.googleapis.com',
      path: '/oauth2/v1/tokeninfo?access_token=' + this.token
    };
    return https.get(options, function(res) {
      return res.on('data', function(data) {
        var json;
        json = JSON.parse(data.toString());
        if (!json.error) {
          _this.validateOK_(md5(json.user_id));
          return fn();
        } else {
          return _this.socket.emit('need login');
        }
      });
    });
  };

  return User;

})();

exports.User = User;
