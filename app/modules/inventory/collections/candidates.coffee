module.exports = Backbone.Collection.extend
  model: require '../models/candidate'
  comparator: 'authors'