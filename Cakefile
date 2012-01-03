
sys = require 'sys'
exec = (require 'child_process').exec

BASE_PATH = 'public/javascripts/'
FILES = [
  'utils.coffee'
, 'classes.coffee'
, 'init.coffee'
]
FILES[_i] = BASE_PATH + file  for file in FILES
FILENAME = "#{BASE_PATH}client" # write your game title.

task 'compile', "compile and minify #{FILENAME}.", (options) ->
  outputErr = (err, stdout, stderr) ->
    throw err if err
    if stdout or stderr
      console.log "#{stdout} #{stderr}"
  if FILES.length is 1
    exec "coffee -c #{FILENAME}.js #{FILES[0]}", outputErr
  else
    exec "coffee -cj #{FILENAME} #{FILES.join ' '}", outputErr 
  exec "yuicompressor #{FILENAME}.js > #{FILENAME}.min.js", outputErr
