# Forked from: https://github.com/KyleNeedham/autocomplete/blob/master/src/autocomplete.behavior.coffee
rateLimit = 200
Suggestions = require '../collections/suggestions'
SuggestionsList = require '../views/behaviors/suggestions'

module.exports = Marionette.Behavior.extend
  events:
    'keyup @ui.autocomplete': 'onKeyUp'
    'keydown @ui.autocomplete': 'onKeyDown'
    'click .close': 'hideDropdown'

  initialize: (options)->
    @visible = no
    @suggestions = Suggestions options
    # throttling to take advantage of match_phrase_prefix search
    @lazyUpdateQuery = _.throttle @updateQuery, rateLimit

    @_startListening()

  _startListening: ->
    @listenTo @suggestions, 'selected:value', @completeQuery.bind(@)
    @listenTo @suggestions, 'highlight', @fillQuery.bind(@)

  onRender: ->
    @_setInputAttributes()
    @_buildElement()

  # Wrap the input element inside the container template
  # and then append collectionView
  _buildElement: ->
    @container = $ '<div class="ac-container"></div>'
    @collectionView = new SuggestionsList { collection: @suggestions }

    @ui.autocomplete.replaceWith @container

    @container
    .append @ui.autocomplete
    .append @collectionView.render().el

  _setInputAttributes: ->
    @ui.autocomplete.attr
      autocomplete: off
      spellcheck: off
      dir: 'auto'

  onKeyDown: (e)->
    key = getActionKey e
    # only addressing 'tab' as it isn't caught by the keyup event
    if key is 'tab'
      # In the case the dropdown was shown and a value was selected
      # @fillQuery will have been triggered, the input filled
      # and the selected suggestion kept at end: we can let the event
      # propagate to move to the next input
      @hideDropdown()

  onKeyUp: (e)->
    e.preventDefault()
    e.stopPropagation()

    value = @ui.autocomplete.val()
    if value.length is 0
      @hideDropdown()
    else
      @showDropdown()
      actionKey = getActionKey e
      if actionKey? then @keyAction actionKey, e
      else @lazyUpdateQuery value

  keyAction: (actionKey, e)->
    # actions happening in any case
    switch actionKey
      when 'esc' then return @hideDropdown()

    # actions conditional to suggestions state
    unless @suggestions.isEmpty()
      switch actionKey
        when 'right'
          if isSelectionEnd(e) then @suggestions.trigger 'select:from:key'
        when 'enter' then @suggestions.trigger 'select:from:key'
        when 'down' then @suggestions.trigger 'highlight:next'
        when 'up' then @suggestions.trigger 'highlight:previous'
        when 'home' then @suggestions.trigger 'highlight:first'
        when 'end' then @suggestions.trigger 'highlight:last'

  showDropdown: ->
    @visible = true
    @ui.autocomplete.parent().find('.ac-suggestions').show()

  hideDropdown: ->
    @visible = false
    @ui.autocomplete.parent().find('.ac-suggestions').hide()

  # Update suggestions list, never directly call this use @lazyUpdateQuery
  # which is a limit throttled alias.
  updateQuery: (query)->
    @suggestions.trigger 'find', query

  # Complete the query using the highlighted or the clicked suggestion.
  fillQuery: (suggestion)->
    @ui.autocomplete
    .val suggestion.get('label')
    .attr 'data-autocomplete-value', suggestion.id

  # Complete the query using the selected suggestion.
  completeQuery: (suggestion)->
    _.log suggestion, 'completeQuery'
    @fillQuery suggestion
    @hideDropdown()

  # Clean up
  onDestroy: -> @collectionView.destroy()

# Check to see if the cursor is at the end of the query string.
isSelectionEnd = (e)->
  { value, selectionEnd } = e.target
  return value.length is selectionEnd

getActionKey = (e)->
  key = e.which or e.keyCode
  return actionKeysMap[key]

actionKeysMap =
  9: 'tab'
  13: 'enter'
  27: 'esc'
  35: 'end'
  36: 'home'
  37: 'left'
  38: 'up'
  39: 'right'
  40: 'down'