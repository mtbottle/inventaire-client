module.exports.initialize = ->

  # override window.onerror to always log the stacktrace
  window.onerror = ->

    # avoid using utils that weren't defined yet
    args = [].slice.call(arguments, 0)

    if args?[4]?
      name = args[4].name

      if name is 'InvalidStateError'
        # already handled at feature_detection, no need to let it throw
        # and report to server
        return console.warn 'InvalidStateError: no worries, already handled'

      if name is 'ViewDestroyedError'
        # ViewDestroyedError are anoying but not critical: debugged from development
        # but not worth the noise in production logs
        return console.warn 'ViewDestroyedError: not reported'

    err = parseErrorObject.apply null, args

    # excluding Chrome that do log the stacktrace by default
    unless window.navigator.webkitGetGamepads?
      console.error.apply console, err, '(handled by window.onerror)'

    window.reportErr(err)



parseErrorObject = (errorMsg, url, lineNumber, columnNumber, errObj)->
  # other arguments aren't necessary as already provided by Firefox
  # console.log {stack: errObj.stack}
  if errObj
    { stack, context } = errObj
    # prerender error object doesnt seem to have a stack, thus the stack?
    stack = stack?.split('\n')
    report = ["#{errorMsg} #{url} #{lineNumber}:#{columnNumber}", stack]
    if context? then report.push context
    return report
  else
    return [ errorMsg, url, lineNumber, columnNumber ]


window.reportErr = (report)->
  unless report?.error?
    err = report
    report =
      error: err

  report.context = getContext()
  if app?.session?.recordError? then app.session.recordError report
  else $.post '/api/logs/public', report

getContext = ->
  context = []
  if app?.user?.loggedIn
    id = app.user.id
    username = app.user.get('username')
    if id? and username?
      userData = "user: #{id} (#{username})"
    else
      userData = "user logged in but error happened before data arrived"
  else
    userData = "user: not logged user"

  context = [
    userData
    navigator.userAgent
  ]

  return context