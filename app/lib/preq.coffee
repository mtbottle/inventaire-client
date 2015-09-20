Promise::fail = Promise::caught
Promise::always = Promise::finally

Promise.onPossiblyUnhandledRejection (err)->
  label = "[PossiblyUnhandledError] #{err.name}: #{err.message} (#{typeof err.message})"
  stack = err?.stack?.split('\n')
  report = {label: label, error: err, stack: stack}
  if err.message is "[object Object]"
    report.clue = clue = "this is probably an error from a jQuery promise wrapped into a Bluebird one"
  window.reportErr report
  console.error label, stack, clue

module.exports =
  get: (url, options)->
    CORS = options?.CORS
    if _.localUrl(url) or CORS then jqPromise = $.get(url)
    else jqPromise = $.get app.API.proxy(url)

    return wrap(jqPromise)

  post: (url, body)-> wrap($.post(url, body))
  put: (url, body)-> wrap($.put(url, body))
  delete: (url)-> wrap($.delete(url))
  getScript: (url)-> wrap($.getScript(url))

  start: -> Promise.resolve()
  resolve: (res)-> Promise.resolve(res)
  reject: (err)-> Promise.reject(err)

  catch401: (err)-> if err.status is 401 then return
  catch404: (err)-> if err.status is 404 then return


wrap = (jqPromise)->
  return new Promise (resolve, reject)->
    jqPromise
    .then resolve
    .fail (err)-> reject rewriteError(err)

rewriteError = (err)->
  {status, statusText, responseText, responseJSON} = err

  error = new Error "#{status}: #{statusText} - #{responseText}"
  return _.extend error,
    status: status
    statusText: statusText
    responseText: responseText
    responseJSON: responseJSON