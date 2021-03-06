books_ = require 'lib/books'
wd_ = require 'lib/wikidata'
WikidataEntity = require './models/wikidata_entity'
IsbnEntity = require './models/isbn_entity'
InvEntity = require './models/inv_entity'
Entities = require './collections/entities'
AuthorLi = require './views/author_li'
EntityShow = require './views/entity_show'
EntityCreate = require './views/entity_create'
GenreLayout= require './views/genre_layout'
error_ = require 'lib/error'

module.exports =
  define: (module, app, Backbone, Marionette, $, _) ->
    EntitiesRouter = Marionette.AppRouter.extend
      appRoutes:
        'entity/:uri(/:label)/add(/)': 'showAddEntity'
        'entity/:uri(/:label)(/)': 'showEntity'

    app.addInitializer ->
      new EntitiesRouter
        controller: API

  initialize: ->
    setHandlers()
    app.entities = new Entities
    app.entities.data = require('./entities_data')(app, _, _.preq)

API =
  showEntity: (uri, label, params, region)->
    region or= app.layout.main
    app.execute 'show:loader', {region: region}

    [prefix, id] = getPrefixId uri
    unless prefix? and id?
      _.warn 'prefix or id missing at showEntity'

    refresh = params?.refresh
    if refresh then app.execute 'qlabel:refresh'

    @_getEntityView prefix, id, refresh
    .then region.show.bind(region)
    .catch @solveMissingEntity.bind(@, prefix, id)
    .catch (err)->
      _.error err, 'couldnt showEntity'
      app.execute 'show:404'

  _getEntityView: (prefix, id, refresh)->
    @getEntityModel prefix, id, refresh
    .then _.Tap(@_replaceEntityPathname.bind(@))
    .then @_getDomainEntityView.bind(@, prefix, refresh)

  _replaceEntityPathname: (entity)->
    # correcting possibly custom entity label
    app.navigateReplace entity.get('pathname')

  _getDomainEntityView: (prefix, refresh, entity)->
    switch prefix
      when 'isbn', 'inv' then @getCommonBookEntityView entity
      when 'wd' then @getWikidataEntityView entity, refresh
      else _.error "getDomainEntityView err: unknown domain #{prefix}"

  getWikidataEntityView: (entity, refresh)->
    switch wd_.type entity
      when 'human' then @getAuthorView entity, refresh
      when 'book' then @getCommonBookEntityView entity
      # display anything else as a genre
      # so that in the worst case it's just a page with a few data
      # and not a page you can 'add to your inventory'
      else new GenreLayout {model: entity}

  getCommonBookEntityView: (entity)->
    new EntityShow {model: entity}

  getAuthorView: (entity, refresh)->
    new AuthorLi
      model: entity
      standalone: true
      displayBooks: true
      initialLength: 20
      refresh: refresh

  getEntitiesModels: (prefix, ids, refresh)->
    # make sure its a 'true' flag and not an object incidently passed
    refresh = refresh is true
    try Model = getModelFromPrefix(prefix)
    catch err then return _.preq.reject(err)

    app.entities.data.get prefix, ids, 'collection', refresh
    .then (data)->
      unless data?
        throw error_.new 'no data at getEntitiesModels', arguments

      models = data.map (el)->
        # main reason for missing entities:
        # no pagination makes request overflow the source API limit
        # ex: wikidata limits to 50 entities per calls
        unless el?
          return _.warn 'missing entity(possible reason: reached API limit, pagination is needed)'
        model = new Model(el)
        app.entities.add model
        return model
      return models

  getEntitiesModelsWithCatcher: ->
    @getEntitiesModels.apply @, arguments
    .catch _.Error('getEntitiesModels err')

  getEntityModel: (prefix, id, refresh)->
    unless prefix? and id?
      throw error_.new 'missing prefix or id', arguments

    @getEntitiesModels prefix, id, refresh
    .then (models)->
      if models?[0]? then return models[0]
      else
        # Some instance of this problem seem to be due to the server
        # caching empty results returned, possibly when API quota where passed?!?
        # Another case seem to be that an item was created using an isbn can't be found later
        # ex: https://inventaire.io/inventory/bnnz/isbn:2070360555/Fondation_Et_Empire
        _.log "getEntityModel entity_not_found: #{prefix}:#{id}"
        throw error_.new 'entity_not_found', [prefix, id, models]

  showAddEntity: (uri)->
    [prefix, id] = getPrefixId(uri)
    if prefix? and id?
      @getEntityModel(prefix, id)
      .then (entity)-> app.execute 'show:item:creation:form', {entity: entity}
      .catch @solveMissingEntity.bind(@, prefix, id)
      .catch _.Error('showAddEntity err')

  solveMissingEntity: (prefix, id, err)->
    if err.message is 'entity_not_found' then @showCreateEntity id
    else throw err

  showCreateEntity: (isbn)->
    app.layout.main.show new EntityCreate
      data: isbn
      standalone: true

  getEntityPublicItems: (uri)->
    _.preq.get app.API.items.publicByEntity(uri)


setHandlers = ->
  app.commands.setHandlers
    'show:entity': (uri, label, params, region)->
      API.showEntity uri, label, params, region
      path = "entity/#{uri}"
      path += "/#{label}"  if label?
      app.navigate path

    'show:entity:from:model': (model, params, region)->
      [ uri, label ] = model.gets 'uri', 'label'
      if uri? and label?
        app.execute 'show:entity', uri, label, params, region
      else throw new Error 'couldnt show:entity:from:model'

    'show:entity:refresh': (model)->
      app.execute 'show:entity:from:model', model, { refresh: true }

  app.reqres.setHandlers
    'get:entity:model': getEntityModel
    'get:entities:models': API.getEntitiesModelsWithCatcher.bind(API)
    'save:entity:model': saveEntityModel
    'get:entity:public:items': API.getEntityPublicItems
    'get:entities:labels': getEntitiesLabels
    'create:entity': createEntity
    'get:entity:local:href': getEntityLocalHref
    'normalize:entity:uri': normalizeEntityUri

getEntityModel = (prefix, id)->
  [prefix, id] = getPrefixId(prefix, id)
  if prefix? and id? then API.getEntityModel prefix, id
  else throw error_.new 'missing prefix or id', arguments

getEntitiesLabels = (Qids)->
  return Qids.map (Qid)-> app.entities.byUri("wd:#{Qid}")?.get 'label'

getPrefixId = (prefix, id)->
  # resolving the polymorphic interface
  # accepts 'prefix', 'id' or 'prefix:id'
  # returns ['prefix', 'id']
  unless id? then [prefix, id] = prefix?.split ':'
  if prefix? and id? then return [prefix, id]
  else
    throw new Error "prefix and id not found for: #{prefix} / #{id}"

getModelFromPrefix = (prefix)->
  switch prefix
    when 'wd' then WikidataEntity
    when 'isbn' then IsbnEntity
    when 'inv' then InvEntity
    else throw new Error("prefix not implemented: #{prefix}")

saveEntityModel = (prefix, data)->
  if data?.id?
    app.entities.data[prefix].local.save(data.id, data)
  else _.error arguments, 'couldnt save entity model'

createEntity = (data)->
  app.entities.data.inv.local.post(data)
  .then (entityData)->
    _.type entityData, 'object'
    if entityData.isbn? then model = new IsbnEntity entityData
    else model = new InvEntity entityData
    app.entities.add model
    return model

getEntityLocalHref = (domain, id, label)->
  # accept both domain, id or uri-style "#{domain}:#{id}"
  [domain, possibleId] = domain?.split(':')
  if possibleId? then [id, label] = [possibleId, id]

  if domain?.length > 0 and id?.length > 0
    href = "/entity/#{domain}:#{id}"
    if label?
      label = _.softEncodeURI(label)
      href += "/#{label}"
    return href
  else throw new Error "couldnt find EntityLocalHref: domain=#{domain}, id=#{id}, label=#{label}"

normalizeEntityUri = (prefix, id)->
  # accepts either a 'prefix:id' uri or 'prefix', 'id'
  # the polymorphic interface is resolved by getPrefixId
  [prefix, id] = getPrefixId(prefix, id)
  if prefix is 'isbn' then id = books_.normalizeIsbn(id)
  return "#{prefix}:#{id}"
