coffee = "./node_modules/coffee-script/bin/coffee"
{spawn} = require("child_process")

exec = (cmd, args=[], cb=->) ->
  bin = spawn(cmd, args)
  bin.stdout.on 'data', (data) ->
    process.stdout.write data
  bin.stderr.on 'data', (data) ->
    process.stderr.write data
  bin.on 'exit', cb

compile = (watch_flag="") ->
  coffee_flags = "-#{watch_flag}cbo"
  exec coffee, [coffee_flags, "./lib/", "./src/lib/"]
  exec coffee, [coffee_flags, "./lib/", "./src/shared/"]

task 'watch', -> compile('w')

task 'build', -> compile()
