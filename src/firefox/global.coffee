{ LiveReloadGlobal, TabState } = require('../common/global')

TabState::send = (message, data={}) ->
  browser.tabs.sendMessage @tab, [message, data]

TabState::bundledScriptURI = -> browser.runtime.getURL('livereload.js')

LiveReloadGlobal.isAvailable = (tab) -> yes

LiveReloadGlobal.initialize()


ToggleCommand =
  invoke: ->
  update: (tabId) ->
    state = LiveReloadGlobal.findState(tabId)
    status = LiveReloadGlobal.tabStatus(tabId)
    browser.browserAction.setTitle { tabId, title: status.buttonToolTip }
    if ( ! state.enabled ) 
      browser.browserAction.setIcon { tabId, path: null }
    else
      browser.browserAction.setIcon { tabId, path: status.buttonIconSVG }


browser.browserAction.onClicked.addListener (tab) ->
  LiveReloadGlobal.toggle(tab.id)
  ToggleCommand.update(tab.id)

browser.tabs.onActivated.addListener (activeInfo) ->
  ToggleCommand.update(activeInfo.tabId)

browser.tabs.onRemoved.addListener (tabId) ->
  LiveReloadGlobal.killZombieTab tabId


browser.runtime.onMessage.addListener ([eventName, data], sender, sendResponse) ->
  # console.log "#{eventName}(#{JSON.stringify(data)})"
  switch eventName
    when 'status'
      LiveReloadGlobal.updateStatus(sender.tab.id, data)
      ToggleCommand.update(sender.tab.id)
    else
      LiveReloadGlobal.received(eventName, data)
