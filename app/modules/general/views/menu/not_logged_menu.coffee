loginPlugin = require 'modules/general/plugins/login'

module.exports = Marionette.ItemView.extend
  template: require './templates/not_logged_menu'
  className: 'notLoggedMenu'
  initialize: ->
    loginPlugin.call @

  onShow: -> app.execute 'foundation:reload'
