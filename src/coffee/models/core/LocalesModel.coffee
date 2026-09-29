class LocalesModel extends Backbone.Model

    defaults :
        code     : null
        language : null
        strings  : null
            
    get_language : =>
        return @get('language')

    getString : (id) =>
        for group, data of @get('strings')
            for key, value of data.strings
                return value if key is id
        console.warn "Locales -> not found string: #{id}"
        null

module.exports = LocalesModel
