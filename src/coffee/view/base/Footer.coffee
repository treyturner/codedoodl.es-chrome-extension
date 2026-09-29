AbstractView = require '../AbstractView'

class Footer extends AbstractView

    template : 'site-footer'

    preinitialize: ->

        @templateVars = 
            desc : @CD_CE().locale.get "footer_desc"


        return

module.exports = Footer
