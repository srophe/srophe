/*!
 * Copyright (c) 2012, Institute for the Study of the Ancient World, New York University
 * Licensed under the BSD License (see LICENSE.txt)
 * @author Nick Rabinowitz
 * @author Sebastian Heath
 */

// removed in production by uglify
if (typeof DEBUG === 'undefined') {
    DEBUG = !(window.console === 'undefined');
    AWLD_VERSION = 'debug';
    // POPUP_CLOSE = 'manual';
    POPUP_CLOSE = 'auto';
    // BASE_URL = '../../src/';
    // cache busting for development
    require.config({
        urlArgs: "bust=" +  (new Date()).getTime()
    });
}

(function(window) {
    if (DEBUG) console.log('AWLD.js loaded');
        
    // utility: simple object extend
    function extend(obj, settings) {
        for (var prop in settings) {
            obj[prop] = settings[prop];
        }
    }
    
    // utility: is this a string?
    function isString(obj) {
        return typeof obj == 'string';
    }
    
    var additionalModules = {},
        // check for baseUrl, autoinit
        docScripts = document.getElementsByTagName('script'),
        scriptEl = docScripts[docScripts.length - 1],
        scriptSrc = scriptEl.src,
        defaultBaseUrl = scriptSrc.replace(/awld\.js.*/, ''),
        autoInit = !!scriptSrc.match(/autoinit/),
    
    /**
     * @name awld
     * @namespace
     * Root namespace for the library
     */
    awld = {

       /**
        * @type Boolean
        * debug flag
       */
        debug: false,

        /**
         * @type String
         * Base URL for dependencies; library and module 
         * dependencies will be loaded relative to this URL. 
         * See http://requirejs.org/docs/api.html#config for
         * more information.
         */
        baseUrl: defaultBaseUrl,
        
        /**
         * @type String
         * Path for modules, relative to baseUrl
         */
        modulePath: 'modules/',
        
        /**
         * @type String
         * Path for libraries, relative to baseUrl
         */
        libPath: 'lib/',
        
        /**
         * @type Object
         * Special path definitions for various dependencies.
         * See http://requirejs.org/docs/api.html#config for
         * more information.
         */
        paths: {},
        
        /**
         * @type String
         * Version number
         */
        version: AWLD_VERSION,
        
        /**
         * @type Object[]
         * Array of loaded modules
         */
        modules: [],
        
        /**
         * @type Object
         * Map of loaded modules, keyed by module path
         */
        moduleMap: {},
        
        /**
         * @type Boolean
         * Whether to auto-load data for all identified URIs
         */
        autoLoad: true,
         
        /**
         * @name alwd.popupClose
         * @type String|Number
         * How the popup window should be closed. Options are either a number 
         * (milliseconds to wait before closing) or the string 'manual'.
         */
        popupClose: POPUP_CLOSE,
        
        /**
         * @name alwd.scope
         * @type String|DOM Element
         * Selector or element to limit the scope of automatic resource identification.
         */
        
        /**
         * Register an additional module for awld.js to load (if its URIs are found)
         * @function
         * @param {String} uriRoot      Root for resource URIs managed by this module
         * @param {String} path         Path to the module, either a fully qualified URL or
         *                              a path relative to awld.js
         */
        registerModule: function(uriRoot, path) {
            additionalModules[uriRoot] = path;
        },
        
        /**
         * Extend the awld object with custom settings.
         * @function
         * @param {Object} settings     Hash of settings to apply
         */
        extend: function(settings) {
            extend(awld, settings);
        }
        
    },
    
    /**
     * @function
     * Initialize the library, loading and running modules based on page content
     */
    init = awld.init = function(opts) {
        if (DEBUG) console.log('Initializing library');
        
        // process arguments
        var isScope = isString(opts) || (opts && (opts.nodeType || opts.jquery)),
            isPlainObject = opts === Object(opts) && !isScope;
            
        // an object argument is configuration
        if (isPlainObject) awld.extend(opts);
        
        var scope = isScope ? opts : awld.scope,
            // check for existing jQuery
            jQuery = window.jQuery,
            // check for old versions of jQuery
            oldjQuery = jQuery && !!jQuery.fn.jquery.match(/^1\.[0-4]/),
            paths = awld.paths,
            libPath = awld.libPath,
            modulePath = awld.modulePath,
            onload = awld.onLoad,
            localJqueryPath = libPath + 'jquery/jquery-1.7.2.min',
            noConflict;
        
        // check for jQuery 
        if (!jQuery || oldjQuery) {
            // load if it's not available or doesn't meet min standards
            paths.jquery = localJqueryPath;
            noConflict = oldjQuery;
        } else {
            // register the current jQuery
            define('jquery', [], function() { return jQuery; });
        }
        
        // add libraries - XXX: better way?
        paths.handlebars = libPath + 'handlebars.runtime';
        paths.mustache = libPath + 'mustache.0.5.0-dev';
        
        // set up require
        require.config({
            baseUrl: awld.baseUrl,
            paths: paths 
        });
        
        // load registry and initialize modules
        require(['jquery', 'registry', 'ui', 'types'], function($, registry, ui, types) {
        
            // add any additional modules
            $.extend(registry, additionalModules);
        
            // deal with jQuery versions if necessary
            if (noConflict) $.noConflict(true);
            
            // add a jquery-dependent utility
            awld.accessor = function(xml) {
                $xml = $(xml);
                return function(selector, attr) {
                    var text = $(selector, $xml).map(function() {
                            return attr ? $(this).attr(attr) : $(this).text();
                        }).toArray();
                    return text.length > 1 ? text : text[0];
                };
            };
            
            /**
             * @name awld.Resource
             * @class
             * Base class for resources
             */
            var Resource = awld.Resource = function(opts) {
                var readyHandlers = [],
                    module = opts.module,
                    noFetch = module.noFetch,
                    dataType = module.dataType,
                    jsonp = dataType == 'jsonp',
                    cors = module.corsEnabled,
                    parseData = module.parseData,
                    fetching = false,
                    loaded = false,
                    yqlUrl = function(uri) {
                        return 'http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20' + dataType +
                            '%20where%20url%3D%22' + uri + '%22&format=' + dataType +
                            '&diagnostics=false&callback=?';
                    };
                return $.extend({
                    // do something when data is loaded
                    ready: function(f) {
                        if (loaded || noFetch) f();
                        else {
                            readyHandlers.push(f);
                            this.fetch();
                        }
                    },
                    // load data for this resource
                    fetch: function() {
                        // don't allow multiple reqs
                        if (!fetching && !noFetch) {
                            fetching = true;
                            var res = this,
                                parseResponse = parseData,
                                options = $.extend({
                                    url: res.uri,
                                    dataType: dataType,
                                    success: function(data) {
                                        // save data
                                        try {
                                            res.data = parseResponse(data);
                                            // potentially set type
                                            if (!res.type) res.type = types.map(module.getType(data));
                                        } catch(e) {
                                            if (DEBUG) console.error('Error loading data for ' + res.uri,  data, e);
                                        }
                                        // invoke any handlers
                                        readyHandlers.forEach(function(f) { 
                                            f(res);
                                        });
                                        loaded = res.loaded = true;
                                        if (DEBUG) console.log('Loaded resource', res.uri);
                                    },
                                    error: function() {
                                        if (DEBUG) console.error('Resource request failed', arguments);
                                    }
                                }, module.ajaxOptions),
                                // make a request using YQL as a JSONP proxy
                                makeYqlRequest = function() {
                                    if (DEBUG) console.log('Making YQL request for ' + res.uri);
                                    options.url = yqlUrl(options.url);
                                    options.dataType = 'jsonp';
                                    parseResponse = function(data) {
                                        data = data && (data.results && data.results[0] || data.query.results) || {};
                                        return parseData(data);
                                    };
                                    $.ajax(options);
                                };
                            // allow CORS to fallback on YQL
                            if (!jsonp && cors) {
                                options.error = function() {
                                    if (DEBUG) console.warn('CORS fail for ' + res.uri);
                                    makeYqlRequest();
                                };
                            }
                            // make the request
                            if (DEBUG) console.log('Fetching ' + res.uri);
                            if (jsonp || cors || module.local) $.ajax(options);
                            else makeYqlRequest();
                        }
                    },
                    name: function() {
                        return this.data && this.data.name || this.linkText;
                    }
                }, opts);
            };
            
            /**
             * @name awld.Modules
             * @class
             * Base class for modules
             */
            var Module = awld.Module = function(opts) {
                var cache = {},
                    identity = function(d) { return d; },
                    noop = function() {};
                return $.extend({
                    // by default, retrieve and cache all resources
                    init: function() {
                        var module = this,
                            resources = module.resources = [];
                        // create Resource for each unique URI
                        module.resourceMap = module.$refs.toArray()
                            .reduce(function(agg, el) {
                                var $ref = $(el),
                                    href = $ref.attr('href'),
                                    type = types.fromClass($ref.attr('class')) || types.map(module.type);
                                if (!(href in agg)) {
                                    agg[href] = Resource({
                                        module: module,
                                        uri: module.toDataUri(href),
                                        href: href,
                                        linkText: $ref.attr('title') || $ref.text(),
                                        type: type
                                    });
                                    // add to array
                                    resources.push(agg[href]);
                                }
                                // add resource to element
                                $ref.data('resource', agg[href]);
                                return agg;
                            }, {});
                        // auto load if requested
                        if (awld.autoLoad) {
                            resources.forEach(function(res) {
                                res.fetch();
                            });
                        }
                        // add pop-up for each resource
                        module.$refs.each(function() {
                            var $ref = $(this),
                                res = $ref.data('resource');
                            // do a jig to deal with unloaded resources
                            ui.addPopup($ref, function(callback) {
                                res.ready(function() {
                                    callback(module.detailView(res));
                                });
                            });
                        });
                        // hook for further initialization
                        module.initialize();
                    },
                    // translate human URI to API URI - default is the same
                    toDataUri: identity,
                    // parse data returned from server
                    parseData: identity,
                    // set type based on data
                    getType: noop,
                    dataType: 'json',
                    // detail view for popup window
                    detailView: ui.detailView,
                    initialize: noop
                }, opts);
            };
            
            // load machinery
            var target = 0,
                loaded = 0,
                modules = awld.modules,
                loadMgr = function(moduleName, module) {
                    if (DEBUG) console.log('Loaded module: ' + moduleName);
                    // add to lists
                    awld.moduleMap[moduleName] = module;
                    modules.push(module);
                    // check for complete
                    if (++loaded == target) {
                        if (DEBUG) console.log('All modules loaded');
                        awld.loaded = true;
                        // init ui
                        ui.init(modules);
                    }
                };
            
            // wrap in ready, as this looks through the DOM
            $(function() {
            
                // constrain scope based on markup
                var scopeSelector = '.awld-scope';
                if (!scope && $(scopeSelector).length)
                    scope = scopeSelector;
            
                // look for modules to initialize
                $.each(registry, function(uriBase, moduleName) {
                    // look for links with this URI base
                    var $refs = $('a[href^="' + uriBase + '"]', scope),
                        path = moduleName.indexOf('http') === 0 ? moduleName : modulePath + moduleName;
                    if ($refs.length) {
                        if (DEBUG) console.log('Found links for module: ' + moduleName);
                        target++;
                        // load module
                        require([path], function(module) {
                            // initialize with cached references
                            module.$refs = $refs;
                            module.moduleName = moduleName;
                            module = Module(module);
                            module.init();
                            // update manager
                            loadMgr(moduleName, module);
                        });
                    }   
                });
                
            });
            
        });
    };
    
    // add to global namespace
    window.awld = awld;
    
    if (autoInit) init();
    
})(window);
