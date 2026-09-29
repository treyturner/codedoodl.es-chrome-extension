AbstractView = require './view/AbstractView'
Preloader    = require './view/base/Preloader'
Header       = require './view/base/Header'
Wrapper      = require './view/base/Wrapper'
Footer       = require './view/base/Footer'
ShowAppsBtn  = require './view/base/ShowAppsBtn'
MediaQueries = require './utils/MediaQueries'

class AppView extends AbstractView

    template : 'main'

    $window  : null
    $body    : null

    wrapper  : null
    footer   : null

    dims :
        w : null
        h : null
        o : null
        c : null

    # events :
    #     'click a' : 'linkManager'

    EVENT_UPDATE_DIMENSIONS : 'EVENT_UPDATE_DIMENSIONS'

    MOBILE_WIDTH : 700
    MOBILE       : 'mobile'
    NON_MOBILE   : 'non_mobile'

    constructor : ->

        super()

        @$window = $(window)
        @$body   = $('body').eq(0)

        return

    disableTouch: =>

        @$window.on 'touchmove', @onTouchMove

        return

    enableTouch: =>

        @$window.off 'touchmove', @onTouchMove

        return

    onTouchMove: ( e ) ->

        e.preventDefault()

        return

    render : =>

        @bindEvents()

        @preloader    = new Preloader

        @header  = new Header
        @wrapper = new Wrapper
        @footer  = new Footer

        @
            .addChild @header
            .addChild @wrapper
            .addChild @footer

        @checkOptions()

        @onAllRendered()

        return

    bindEvents : =>

        @on 'allRendered', @onAllRendered

        @onResize()

        @onResize = _.debounce @onResize, 300
        @$window.on 'resize orientationchange', @onResize

        return

    onAllRendered : =>

        # console.log "onAllRendered : =>"

        @$body.prepend @$el

        @begin()

        return

    begin : =>

        @trigger 'start'

        @CD_CE().router.start()

        @preloader.hide()

        return

    onResize : =>

        @getDims()

        return

    getDims : =>

        w = window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth
        h = window.innerHeight or document.documentElement.clientHeight or document.body.clientHeight

        @dims =
            w : w
            h : h
            o : if h > w then 'portrait' else 'landscape'
            c : if w <= @MOBILE_WIDTH then @MOBILE else @NON_MOBILE

        @trigger @EVENT_UPDATE_DIMENSIONS, @dims

        return

    linkManager : (e) =>

        href = $(e.currentTarget).attr('href')

        return false unless href

        @navigateToUrl href, e

        return

    navigateToUrl : ( href, e = null ) =>

        route   = if href.match(@CD_CE().BASE_URL) then href.split(@CD_CE().BASE_URL)[1] else href
        section = if route.indexOf('/') is 0 then route.split('/')[1] else route

        if @CD_CE().nav.getSection section
            e?.preventDefault()
            @CD_CE().router.navigateTo route
        else 
            @handleExternalLink href

        return

    handleExternalLink : (data) => 

        ###

        bind tracking events if necessary

        ###

        return

    checkOptions : =>

        if @CD_CE().appData.OPTIONS.show_apps_btn

            @showAppsBtn = new ShowAppsBtn
            @addChild @showAppsBtn

        null

module.exports = AppView
