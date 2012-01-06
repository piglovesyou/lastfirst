
{exec} = (require 'child_process')

BASE_PATH = 'public/javascripts/'
addBasePath = (paths) ->
  paths[_i] = BASE_PATH + path  for path in paths

LIBS = addBasePath([
  'libs/socket.io.js'
  'libs/underscore-min.js'
  'libs/jquery-1.7.min.js'
])

FILES = addBasePath([
  'utils/utils.coffee'
  'classes/classes.coffee'
  'init/init.coffee'
])

MY_SCRIPT_FILENAME = "#{BASE_PATH}my"
OUTPUT_FILENAME = "#{BASE_PATH}client"



outputHandling = (err, stdout, stderr) ->
  throw err if err
  if stdout or stderr
    console.log "#{stdout} #{stderr}"

onCoffeeCompiled = (err, stdout, stderr) ->
  outputHandling(err, stdout, stderr)
  exec "yuicompressor #{MY_SCRIPT_FILENAME}.js > #{MY_SCRIPT_FILENAME}.min.js", onYUICompressed

onYUICompressed = (err, stdout, stderr) ->
  outputHandling(err, stdout, stderr)
  coms = []
  for min in ['', '.min']
    coms[_i] = "cat #{LIBS.join ' '} #{MY_SCRIPT_FILENAME}#{min}.js > #{OUTPUT_FILENAME}#{min}.js"
  exec coms.join(' | '), onConcatFile

onConcatFile = (err, stdout, stderr) ->
  outputHandling(err, stdout, stderr)
  exec "rm #{MY_SCRIPT_FILENAME}.js #{MY_SCRIPT_FILENAME}.min.js", outputHandling



# tasks
task 'c', "compile and minify #{MY_SCRIPT_FILENAME}.", (options) ->
  exec "coffee -cj #{MY_SCRIPT_FILENAME} #{FILES.join ' '}", onCoffeeCompiled


