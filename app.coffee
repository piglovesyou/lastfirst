express = require("express")
mongoose = require("mongoose")
_ = require("underscore")

PostSchema = new mongoose.Schema(
  name: String
  title: String
  body: String
  createdAt: Date
)

mongoose.model('Post', PostSchema)

mongoose.connect('mongodb://localhost/ndb')

Post = mongoose.model('Post')



app = module.exports = express.createServer()
io = require('socket.io').listen(app)
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )
app.configure "production", ->
  app.use express.errorHandler()







# socket emitting
updateOptions =
  sort: [['createdAt', 'descending']]
  limit: 5
emitUpdateTo = (socket) ->
  Post.find {},[],updateOptions, (err, docs) ->
    socket.emit 'update', docs.reverse()

# sockets listening
io.sockets.on 'connection', (socket) ->
  emitUpdateTo(socket)
  socket.on 'post', (data) ->
    post = new Post()
    data.body = '(empty body)' if _.isNull(data.body)
    post = _.extend(post, data)
    post.save (err) ->
      if not err
        emitUpdateTo(io.sockets)

    

    

# get 
app.get "/", (req, res) ->
  res.render "index",
    title: "Express"

app.listen 3000

