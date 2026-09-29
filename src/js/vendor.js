import $ from 'jquery';
import _ from 'underscore';
import Backbone from 'backbone';

// The CoffeeScript UI and precompiled templates share these package instances.
window.$ = window.jQuery = $;
window._ = _;
Backbone.$ = $;
window.Backbone = Backbone;

document.documentElement.classList.replace('no-js', 'js');
