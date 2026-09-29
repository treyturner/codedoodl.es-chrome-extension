LocalesModel = require '../models/core/LocalesModel'

###
# Locale Loader #

Fires back an event when complete

###
class Locale

    lang     : null
    data     : null
    callback : null
    default  : 'en-gb'

    constructor : (data, cb) ->

        ### start Locale Loader, define locale based on browser language ###

        @callback = cb

        @lang = @getLang()

        @parseData data

        null
            
    getLang : =>

        if window.location.search and window.location.search.match('lang=')

            lang = window.location.search.split('lang=')[1].split('&')[0]

        else if window.config.localeCode

            lang = window.config.localeCode

        else

            lang = @default

        lang

    parseData : (data) =>

        ### Fires back an event once it's complete ###

        @data = new LocalesModel data
        @callback?()

        null

    get : (id) =>

        ### get String from locale
        + id : string id of the Localised String
        ###

        return @data.getString id

    getLocaleImage : (url) =>

        return window.config.CDN + "/images/locale/" + window.config.localeCode + "/" + url

module.exports = Locale
