# Prevent default click event behavior selectively

module.exports = (e)->
  # largely inspired by
  # https://github.com/jmeas/backbone.intercept/blob/master/src/backbone.intercept.js

  # Only intercept left-clicks
  if e.which isnt 1 then return

  # Don't intercept if ctrlKey is pressed
  # it should open the targeted anchor href in a new tab/window
  # Prevent the normal handler to also fire:
  # `unless _.isOpenedOutside(e) then handler()`
  if _.isOpenedOutside(e) then return

  if e.currentTarget?
    $link = $(e.currentTarget)
    # Get the href; stop processing if there isn't one
    href = $link.attr("href")
    unless href then return

  # Return if the URL is absolute (thus with ://)
  # or if the protocol is mailto or javascript
  if /^#|javascript:|mailto:|(?:\w+:)?\/\//.test(href) then return

  # If we haven't been stopped yet, then we prevent the default action
  e.preventDefault()
