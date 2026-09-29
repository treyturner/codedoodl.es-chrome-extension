AbstractModel        = require '../AbstractModel'
NumberUtils          = require '../../utils/NumberUtils'
CodeWordTransitioner = require '../../utils/CodeWordTransitioner'

# Catalogue input is normalized once, without changing the cached/API objects.
# Ordinary Backbone.set remains available for updates such as viewed-state rotation.
normalizeDoodle = (attrs = {}) ->
    data = _.extend {}, attrs
    data.author = _.extend {name: '', github: '', website: '', twitter: ''}, attrs.author
    data.interaction = _.extend {mouse: null, keyboard: null, touch: null}, attrs.interaction
    data.tags = (attrs.tags or []).slice()
    if data.slug
        data.url = window.config.hostname + '/' + window.config.routes.DOODLES + '/' + data.slug
    if data.index? and data.index isnt ''
        data.index_padded = NumberUtils.zeroFill data.index, 3
        data.indexHTML = data.index_padded.split('').map((char) ->
            className = if char is '0' then 'index-char-zero' else 'index-char-nonzero'
            "<span class=\"#{className}\">#{char}</span>"
        ).join('')
    data.scrambled =
        name: CodeWordTransitioner.getScrambledWord(data.name or '')
        author_name: CodeWordTransitioner.getScrambledWord(data.author.name)
    data

class DoodleModel extends AbstractModel

    defaults : ->
        # from manifest
        "id" : ""
        "index": ""
        "name" : ""
        "author" :
            "name"    : ""
            "github"  : ""
            "website" : ""
            "twitter" : ""
        "instructions": ""
        "description": ""
        "tags" : []
        "interaction" :
            "mouse"    : null
            "keyboard" : null
            "touch"    : null
        "created" : ""
        "slug" : ""
        "shortlink" : ""
        "colour_scheme" : ""
        # site-only
        "index_padded" : ""
        "indexHTML" : ""
        "source"    : ""
        "url"       : ""
        "scrambled" :
            "name"        : ""
            "author_name" : ""
        "viewed" : false

    constructor : (attrs, options) ->
        super normalizeDoodle(attrs), options

    getAuthorHtml : =>

        portfolio_label = @CD_CE().locale.get "misc_portfolio_label"

        attrs = @get('author')
        html  = ""
        links = []

        html += "#{attrs.name} \\ "

        if attrs.website then links.push "<a href=\"#{attrs.website}\" target=\"_blank\">#{portfolio_label}</a> "
        if attrs.twitter then links.push "<a href=\"http://twitter.com/#{attrs.twitter}\" target=\"_blank\">tw</a>"
        if attrs.github then links.push "<a href=\"http://github.com/#{attrs.github}\" target=\"_blank\">gh</a>"

        html += "#{links.join(' \\ ')}"

        html

module.exports = DoodleModel
