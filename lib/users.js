var Users, instance_, _;

_ = require("underscore");

/*
 Singleton class for managing users.
*/

Users = (function() {

  Users.prototype.users_ = {};

  Users.prototype.penaltyUserIds_ = [];

  function Users() {}

  Users.prototype.add = function(user) {
    if (user.id) return this.users_[user.id] = user;
  };

  Users.prototype.remove = function(id) {
    return delete this.users_[id];
  };

  Users.prototype.has = function(id) {
    return !!this.users_[id];
  };

  Users.prototype.setPenaltyUser = function(id) {
    var _this = this;
    this.penaltyUserIds_.push(id);
    return _.delay(function() {
      var user;
      _this.penaltyUserIds_ = _.without(_this.penaltyUserIds_, id);
      user = _this.users_[id];
      if (user) {
        return user.socket.emit('release penalty', {
          message: 'Now you can post.'
        });
      }
    }, 60 * 60 * 1000);
  };

  Users.prototype.isPenaltyUser = function(id) {
    return _.include(this.penaltyUserIds_, id);
  };

  return Users;

})();

instance_ = null;

exports.getInstance = function() {
  return instance_ || (instance_ = new Users());
};
