
_ = require("underscore")

###
 Singleton class for managing users.
###
class Users
  users_: {}  # only validated users are here.
  penaltyUserIds_: []

  constructor: () ->
  # @param {User} user
  add: (user) ->
    if user.id
      @users_[user.id] = user
  remove: (id) ->
    delete @users_[id]
  has: (id) ->
    !!@users_[id]
  setPenaltyUser: (id) ->
    @penaltyUserIds_.push(id)
    _.delay () =>
      @penaltyUserIds_ = _.without(@penaltyUserIds_, id)
      user = @users_[id]
      if user
        user.socket.emit 'release penalty',
          message: 'Now you can post.'
    , 60 * 60 * 1000
  isPenaltyUser: (id) ->
    _.include(@penaltyUserIds_, id)


instance_ = null
exports.getInstance = () ->
  instance_ or (instance_ = new Users())
  
