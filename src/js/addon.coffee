app = require './app'
entityRepository = require './objectsApi/entityRepository'

customFieldsHandler = require './handlers/customFields'

renderOnDealListPage = require './handlers/renderOnDealListPage'

whenjs = require 'when'

getNewEntityId = ->
  new Date().getTime() + Math.random()

module.exports = addonEntry =
  start: (_taistApi) ->
    #TODO remove on production
    window.app = app
    app.api = _taistApi

    extractNimbleAuthTokenFromRequest()

    waitingForNewDealRequest()

    app.repositories.deals = new entityRepository app.api, 'deals'

    app.repositories.customFields = new entityRepository app.api, 'customFields'
    app.repositories.customFields.load()
    .then () ->
      whenjs.all(
        app.repositories.customFields.getAllEntities().map (repository) ->
          id = repository.id
          app.repositories[id] = new entityRepository(app.api, id)
          app.repositories[id].load()
      )
    .then () ->
      app.repositories.deals.load()
    .then () ->
      setRoutes()
      customFieldsHandler.renderInNewDealDialog()

routesByHashes =
  'app\/deals\/list': -> renderOnDealListPage()
  '^app/deals/view': -> customFieldsHandler.renderInDealViewer()
  '^app/deals/edit': -> customFieldsHandler.renderInDealEditor()
  'app/settings/deals': -> customFieldsHandler.renderInSettings()

setRoutes = ->
  for hashRegexp, routeProcessor of routesByHashes
    do (hashRegexp, routeProcessor) =>
      app.api.hash.when hashRegexp, routeProcessor

proxy = require './tools/xmlHttpProxy'

extractNimbleAuthTokenFromRequest = ->
  proxy.onRequestFinish (request) ->
    url = request.responseURL
    tokenMatches = url.match /\/api\/sessions\/([0-9abcdef-]{36})\?/
    if tokenMatches?
      app.options.nimbleToken = tokenMatches[1]

waitingForNewDealRequest = ->
  proxy.onRequestFinish (request) ->
    url = request.responseURL
    if url.match /\/api\/deals\?/
      #new deal
      dealId = JSON.parse(request.responseText)?.deal?.id
      customFieldsHandler.saveCustomFields dealId, isNew = true
    else if matches = url.match /\/api\/deals\/([0-9a-f]{24})\?_method=PUT/
      #save deal
      dealId = matches[1]
      customFieldsHandler.saveCustomFields dealId, isNew = false
