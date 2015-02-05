app = require './app'
industryField = require './industryField'

module.exports =
  _industryForNewDeal: null
  renderInNewDealDialog: ->
    app.api.wait.elementRender '.DealCreateForm tbody', (dealCreateFormTable) =>
      industrySelectUI = $ @_industrySelectInDealCreationTemplate
      industryEditor = industryField.createValueEditorForNewDeal (selectedIndustry) =>
        @_industryForNewDeal = selectedIndustry
        app.api.log "industry for new deal: ", @_industryForNewDeal

      (industrySelectUI.find '.taist-selectWrapper').append industryEditor

      previousRow = (dealCreateFormTable.find '.fieldCell.stage').parent()

      console.log "rendering: ", industrySelectUI, dealCreateFormTable
      previousRow.after industrySelectUI

  renderInDealViewer: ->
    app.api.wait.elementRender '.DealView .generalInfo', (parentCell) =>
      @_saveIndustryForFreshlyCreatedDeal =>
        @_displayIndustryInDealViewer parentCell

  _saveIndustryForFreshlyCreatedDeal: (callback) ->
    if @_industryForNewDeal?
      industryField.setIndustryInDeal @_getDealIdFromUrl(), @_industryForNewDeal, =>
        @_industryForNewDeal = null
        callback()

    else
      callback()

  _displayIndustryInDealViewer: (parentCell) ->
    ($ '#taist-industryViewer').remove()
    parentCell.append """<div id=\"taist-industryViewer\" class=\"dealMainField\">Industry:&nbsp<div >#{industryField.getIndustryName @_getDealIdFromUrl()}</div> </div>"""

  renderInDealEditor: ->
    app.api.wait.elementRender '.dealInfoTab .leftColumn', (parentColumn) =>
      ($ '#taist-industryEditor').remove()
      industrySelectUI = $ @_industrySelectInDealEditTemplate
      (industrySelectUI.find '.taist-selectWrapper').append(industryField.createValueEditor @_getDealIdFromUrl())
      parentColumn.append industrySelectUI

  _getDealIdFromUrl: -> location.hash.substring((location.hash.indexOf '?id=') + 4)

  renderInSettings: ->
    app.api.wait.elementRender '.SettingsDealsView', (parentEl) =>
      container = $('.taistSettingsContainer', parentEl)
      unless container.length
        container = $('<div class="taistSettingsContainer">').appendTo parentEl
        React = require 'react'
        DictEditor = require './react/dictionaryEditor/dictEditor'

        dict =
          name: 'Industry'
          entities: [
            { id:'1', value:'Health Care' }
            { id:'2', value:'Transportation' }
            { id:'3', value:'Security' }
            { id:'4', value:'Education' }
          ]
          onUpdate: (entities) ->
            dict.entities = entities
            React.render ( DictEditor dict ), container[0]

        React.render ( DictEditor dict ), container[0]

      # settingsWrapperEl = $ """<div class="taistSettingsContainer"><div class="subHeader">Industries</div><br/><br/></div>"""
      # parentEl.append settingsWrapperEl
      # industrySettingsUI = industryField.createSettingsEditor()
      # settingsWrapperEl.append industrySettingsUI

  _industrySelectInDealEditTemplate: "<div id=\"taist-industryEditor\">\n  <div class=\"ContactFieldWidget\">\n    <div class=\"label\">industry:</div>\n    <div class=\"inputField taist-selectWrapper\"></div>\n\n    <div style=\"clear:both\"></div>\n  </div>\n</div>"
  _industrySelectInDealCreationTemplate: "<tr>\n  <td class=\"labelCell\">Industry:</td>\n</tr>\n<tr>\n  <td class=\'fieldCell\'>\n    <div class=\'nmbl-FormListBox\'>\n      <div class=\"taist-selectWrapper\">\n    </div>\n  </td>\n</tr>\n"
