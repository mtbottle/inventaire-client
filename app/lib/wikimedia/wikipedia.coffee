module.exports =
  enWpImage: (enWpTitle)->
    _.preq.get app.API.data.enWpImage enWpTitle
    .get 'url'
    .catch _.ErrorRethrow('enWpImage err')

  extract: (lang, title)->
    _.preq.get app.API.data.wikipediaExtract(lang, title)
    .then (data)->
      { extract, url } = data
      return sourcedExtract extract, url
    .catch _.ErrorRethrow('wikipediaExtract err')


# add a link to the full wikipedia article at the end of the extract
sourcedExtract = (extract, url)->
  if url?
    text = _.i18n 'read_more_on_wikipedia'
    extract += "<br><a href='#{url}' class='source link' target='_blank'>#{text}</a>"

  return extract
