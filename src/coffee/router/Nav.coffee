AbstractView = require '../view/AbstractView'
Router       = require './Router'

class Nav extends AbstractView

    @EVENT_CHANGE_VIEW     : 'EVENT_CHANGE_VIEW'
    @EVENT_CHANGE_SUB_VIEW : 'EVENT_CHANGE_SUB_VIEW'

    sections :
        HOME : 'index.html'

    current  : area : null, sub : null
    previous : area : null, sub : null

    constructor: ->

        super()

        @CD_CE().router.on Router.EVENT_HASH_CHANGED, @changeView

        return

    getSection : (section) =>

        if section is '' then return true

        for sectionName, uri of @sections
            if uri is section then return sectionName

        false

    changeView: (area, sub, params) =>

        console.log "area",area
        console.log "sub",sub
        console.log "params",params

        @previous = @current
        @current  = area : area, sub : sub

        @trigger Nav.EVENT_CHANGE_VIEW, @previous, @current
        @trigger Nav.EVENT_CHANGE_SUB_VIEW, @current


        # @trackPageView()

        null

    # trackPageView : =>

    #     return unless window.ga and @changeViewCount > 1

    #     ga 'send', 'pageview', 'page' : window.location.href.split(@CD().BASE_URL)[1] or '/'

    #     null

module.exports = Nav
