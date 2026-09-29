Analytics    = require './utils/Analytics'
Share        = require './utils/Share'
Templates    = require './data/Templates'
Locale       = require './data/Locale'
Router       = require './router/Router'
Nav          = require './router/Nav'
AppData      = require './AppData'
AppView      = require './AppView'
MediaQueries = require './utils/MediaQueries'

class App

    LIVE        : null
    SITE_URL    : window.config.SITE_URL
    BASE_URL    : window.config.hostname
    ASSETS_URL  : window.config.assets_url
    DOODLES_URL : window.config.doodles_url
    API_HOST    : window.config.API_HOST
    localeCode  : window.config.localeCode
    objReady    : 0

    _toClean   : ['objReady', 'setFlags', 'objectComplete', 'init', 'initObjects', 'initApp', 'go', 'cleanup', '_toClean']

    constructor : (@LIVE) ->

        return null

    setFlags : =>

        ua = window.navigator.userAgent.toLowerCase()

        MediaQueries.setup();

        @IS_ANDROID    = ua.indexOf('android') > -1
        @IS_FIREFOX    = ua.indexOf('firefox') > -1
        @IS_CHROME_IOS = if ua.match('crios') then true else false # http://stackoverflow.com/a/13808053

        null

    objectComplete : =>

        @objReady++
        @initApp() if @objReady >= 4

        null

    init : =>

        @initObjects()

        null

    initObjects : =>

        @appData   = new AppData @objectComplete
        @templates = new Templates window._TEMPLATES, @objectComplete
        @locale    = new Locale window._LOCALE_STRINGS, @objectComplete
        @analytics = new Analytics window._TRACKING, @objectComplete

        # if new objects are added don't forget to change the `@objectComplete` function

        null

    initApp : =>

        @setFlags()

        ### Starts application ###
        @appView = new AppView
        @router  = new Router
        @nav     = new Nav
        @share   = new Share

        @go()

        null

    go : =>

        ### After everything is loaded, kicks off website ###
        @appView.render()

        ### remove redundant initialisation methods / properties ###
        @cleanup()

        null

    cleanup : =>

        for fn in @_toClean
            @[fn] = null
            delete @[fn]

        null

module.exports = App
