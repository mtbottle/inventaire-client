Message = require './models/message'
poster_ = require 'lib/poster'

module.exports = ->
  app.reqres.setHandlers
    'transactions:add': API.addTransaction
    'get:transaction:byId': API.getTransaction
    'transaction:post:message': API.postMessage

  app.request('waitForUserData').then initLateHelpers

API =
  addTransaction: (transaction)->
    app.user.transactions.add transaction

  getTransaction: (id)->
    app.user.transactions.byId id

  postMessage: (transactionId, message, timeline)->
    messegeData =
      transaction: transactionId
      message: message

    mesModel = addMessageToTimeline(messegeData, timeline)

    messegeData.action = 'new-message'

    _.preq.post app.API.transactions, messegeData
    .then poster_.UpdateModelIdRev(mesModel)
    .catch poster_.Rewind(mesModel, timeline)
    .catch _.Error('postMessage')

addMessageToTimeline = (messegeData, timeline)->
  _.extend messegeData,
    user: app.user.id
    created: app.user.id
  mesModel = new Message messegeData
  timeline.add mesModel
  return mesModel

initLateHelpers = ->
  if app.user.transactions?
    filtered = new FilteredCollection app.user.transactions

    getTransactionsByItemId = (itemId)->
      filtered.resetFilters()
      filtered.filterBy 'item', (transac)-> transac.get('item') is itemId
      return filtered

    app.reqres.setHandlers
      'get:transactions:byItemId': getTransactionsByItemId
