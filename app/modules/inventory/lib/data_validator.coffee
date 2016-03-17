error_ = require 'lib/error'

module.exports = (source, data)->
  first20Char = data[0...20]
  unless first20Char is first20Characters[source]
    message = _.i18n 'data_mismatch', { source: _.capitaliseFirstLetter(source) }
    throw error_.new message, first20Char

first20Characters =
  babelio: '"ISBN";"Titre";"Aute'
