AbstractView    = require '../AbstractView'
DoodlePageView     = require '../doodlePage/DoodlePageView'
Nav             = require '../../router/Nav'

class Wrapper extends AbstractView

    VIEW_TYPE_PAGE  : 'page'
    VIEW_TYPE_MODAL : 'modal'

    template : 'wrapper'

    views          : null
    previousView   : null
    currentView    : null
    backgroundView : null

    constructor : ->

        super()

        @views =
            doodle : classRef : DoodlePageView, route : @CD_CE().nav.sections.HOME, view : null, type : @VIEW_TYPE_PAGE

        @createClasses()
        @init()

        # decide if you want to add all core DOM up front, or add only when required, see comments in AbstractViewPage.coffee
        # @addClasses()

        return

    createClasses : =>

        (@views[name].view = new @views[name].classRef) for name, data of @views

        null

    addClasses : =>

         for name, data of @views
            if data.type is @VIEW_TYPE_PAGE then @addChild data.view

        null

    getViewByRoute : (route) =>

        for name, data of @views
            return @views[name] if route is @views[name].route

        if route then return @views.fourOhFour

        null

    init : =>

        @CD_CE().appView.on 'start', @start

        null

    start : =>

        @CD_CE().appView.off 'start', @start

        @bindEvents()
        @updateDims()

        null

    bindEvents : =>

        @CD_CE().nav.on Nav.EVENT_CHANGE_VIEW, @changeView
        @CD_CE().nav.on Nav.EVENT_CHANGE_SUB_VIEW, @changeSubView

        @CD_CE().appView.on @CD_CE().appView.EVENT_UPDATE_DIMENSIONS, @updateDims

        null

    updateDims : =>

        @$el.css 'min-height', @CD_CE().appView.dims.h

        null

    changeView : (previous, current) =>

        if @pageSwitchDfd and @pageSwitchDfd.state() isnt 'resolved'
            do (previous, current) => @pageSwitchDfd.done => @changeView previous, current
            return

        @previousView = @getViewByRoute previous.area
        @currentView  = @getViewByRoute current.area

        if !@previousView
            @transitionViews false, @currentView
        else
            @transitionViews @previousView, @currentView

        null

    changeSubView : (current) =>

        @currentView.view.trigger Nav.EVENT_CHANGE_SUB_VIEW, current.sub

        null

    transitionViews : (from, to) =>

        @pageSwitchDfd = $.Deferred()

        if from and to
            @CD_CE().appView.transitioner.prepare from.route, to.route
            @CD_CE().appView.transitioner.in => from.view.hide => to.view.show => @CD_CE().appView.transitioner.out => @pageSwitchDfd.resolve()
        else if from
            from.view.hide @pageSwitchDfd.resolve
        else if to
            to.view.show @pageSwitchDfd.resolve

        null

module.exports = Wrapper
