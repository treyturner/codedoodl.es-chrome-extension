AbstractView         = require '../AbstractView'
CodeWordTransitioner = require '../../utils/CodeWordTransitioner'

class ShowAppsBtn extends AbstractView

    template : 'show-apps-btn'

    constructor: ->

        super()
        @init()

        return

    init : =>

        return unless @CD_CE().appData.activeDoodle

        @activeColour = if @CD_CE().appData.activeDoodle.get('colour_scheme') is 'light' then 'black' else 'white'

        CodeWordTransitioner.prepare @$el, @activeColour

        @bindEvents()

        null

    bindEvents : =>

        @$el.on 'mouseenter', @onWordEnter
        @$el.on 'mouseleave', @onWordLeave

        @$el.on 'click', @onClick

        null

    onWordEnter : (e) =>
        return unless window.matchMedia('(any-hover: hover) and (any-pointer: fine)').matches

        CodeWordTransitioner.scramble @$el, @activeColour

        null

    onWordLeave : (e) =>
        return unless window.matchMedia('(any-hover: hover) and (any-pointer: fine)').matches

        CodeWordTransitioner.unscramble @$el, @activeColour

        null

    onClick : =>

        chrome.tabs.update url: 'chrome://apps'

        null

module.exports = ShowAppsBtn
