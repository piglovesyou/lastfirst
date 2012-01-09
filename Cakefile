
# Include required libraries.

muffin = require 'muffin'
Q = require 'q'
_ = require 'underscore'
temp = require 'temp'
tempdir = temp.mkdirSync()



# Client scripts setting.

addPath = (path, files) ->
  path += '/'  if /[^\/]$/.test(path)
  files[_i] = path + file  for file in files

LIBS = addPath 'resources/client/libs', [
  'socket.io.js'
  'underscore-min.js'
  'jquery-1.7.min.js'
]
FILES = addPath 'resources/client', [
  'utils/utils.coffee'
  'classes/classes.coffee'
  'init/init.coffee'
]
OUTPUT = "public/javascripts/client"



# Internal functions.

concat = (minify) ->
  min = if minify then '.min' else ''
  my = "#{tempdir}/my#{min}.js"
  q = muffin.exec "cat #{LIBS.join ' '} #{my} > #{OUTPUT}#{min}.js"
  Q.when q[1], (err) ->
    console.log "compiled CLIENT SIDE scripts"
  
minify = (callback) ->
  q = muffin.minifyScript "#{tempdir}/my.js"
  Q.when q, concat.bind(null)

joinAndCompile = (options) ->
  q = muffin.exec "coffee -cj #{tempdir}/my.js #{FILES.join ' '}"  
  Q.when q[1], (err) ->
    if options.minify
      minify(concat.bind(null, true))
    else
      concat(false)



# Options.

option '-w', '--watch', 'continue to watch the files and rebuild them when they change'
option '-m', '--minify', 'minify client side scripts'



# Tasks.

task 'build', 'Build coffeescripts.', (options) ->
  compileClientScripts = true
  muffin.run
    files: './resources/**/*.coffee'
    options: options
    map:
      'resources/server/(.+?).coffee': (matches) ->
        q = muffin.compileScript matches[0], "./lib/#{matches[1]}.js", options
        Q.when q, -> console.log "compiled SERVER SIDE script"
      'resources/client/(.+?).coffee': (matches) ->
        if compileClientScripts
          compileClientScripts = false  # prevent first wasted compiles
          joinAndCompile(options)
    after: ->
      compileClientScripts = true



