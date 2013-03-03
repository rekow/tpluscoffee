#       _      _            __  __
#      | |_  _| |_  __ ___ / _|/ _|___ ___
#      |  _||_   _|/ _/ _ \  _|  _/ -_) -_)
#       \__|  |_|(_)__\___/_| |_| \___\___|
#

# Extends [`t.js`](https://www.github.com/jasonmoo/t.js) with inheritance, extending with named block overrides, includes (partials), macros, and simple, extensible asynchronous template loading and parsing.

# @author  David Rekow <david at davidrekow.com>
# @license MIT
# @version 0.1.0

# For general usage, see the `t.js` [docs](https://www.github.com/jasonmoo/t.js).

# `t+.coffee` additions:

# * Partials & inheritance
#   * Include: `{{&<name>}}`.
#   * Extend, replacing named blocks: 
#
#             {{^parent}}
#                 {{#block1}}content{{/block1}}
#                 {{#block2}}content 2{{/block2}}
#
#     * Extend block `{{^<name>}}` must be first block in template
#     * Content between blocks in child template will be ignored
#   * Interpreted templates cached for fast re-render
# * Simple template management via `t.put(name, template, callback)` and `t.load(name, callback)`
#   * Extensible - simply overwrite `t.put` & `t.load` with your own logic and pass an instance of `t` when calling 'callback'.
#   * Register functions should expect `(name, template, callback)`, while loader functions should accept `name` and pass template to `callback`.
# * Macros
#   * Inline: `{{+<name>(param1, param2...)}}`. If an error occurs, returns `''`.
#   * Block:  
#
#             # If an error occurs, returns <default content>.
#             {{+<name>(param1, param2...)}}
#                 <default content>
#             {{/<name>}}
#
#   * Must be registered first: `t.macro(name, fn)`.

# Save reference to `@t` so we can overwrite.
t = @t

@t = do (t) ->

    # Save reference to call in `parse` so we can put our own `render` on the prototype.
    render = t::render

    _t = t
    t.noConflict = -> (t = _t; _t)

    # Matchers.
    partial = /\{\{\s*?\&\s*?([^\s]+?)\s*?\}\}/g
    extend = /^\{\{\s*?\^\s*?([^\s]+?)\s*?\}\}\n*?([.\n]*)/
    _macro = /\{\{\s*?(\+\s*?([^\(]+))\(([^\)]*)\)\s*?\}\}(?:([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\})?/g
    blocks = /\{\{\s*?(#\s*?([\w]+))\s*?\}\}([\s\S.]*)\{\{\s*?\/\s*?(?:\1|\2)\}\}/g

    triml = /^\s+/
    trimr = /\s+$/

    # Trims a single string or array of strings.
    trim = (str) ->
        if str.charAt
            str = str.replace(triml, '').replace(trimr, '')
        else if str.length
            str[i] = trim(s) for s, i in str
        return str

    # Template cache, used in default `load` method.
    templates = {}

    # Asynchronously caches or retrieves a template. If called with no arguments, returns `templates` cache. If called with just `name` and `callback`, loads template by `name` and passes the `t` instance to `callback`. If called with `name` and `tpl` (`callback` optional), saves template `tpl` by `name` in `templates`. If overwriting `t::load` to enable your own backend, it should conform to this.
    load = (name, tpl, callback) ->

        return templates if not name
        if not callback
            if typeof tpl is 'function'
                callback = tpl
                tpl = null
            else
                tpl = if tpl.t then tpl else new t(tpl)
                tpl.name = name
                templates[name] = tpl
                return

        if typeof name is 'object'
            load(_name, _tpl) for _name, _tpl of name
            return callback and callback()

        if name.length and name.slice and not name.split
            len = name.length
            results = {}
            count = 0

            for _name in name
                load _name, (_tpl) ->
                    results[_name] = _tpl
                    callback and callback(results) if ++count is len

            return

        return callback and callback(templates[name])

    # Macro cache. Macros must be registered before use, by calling `t.macro`.
    macros = {}

    # Loads or caches a macro.
    macro = (name, fn, ctx=null) ->

        return macros if not name

        # Sets a hash of macros.
        if typeof name is 'object'
            ctx = fn or ctx
            macro(_name, _fn, ctx) for _name, _fn of name
            return

        # Sets macro, binding to context `ctx`.
        if fn and typeof fn is 'function'
            macros[name] = ->
                return fn.apply(ctx, arguments)

        # Return macro.
        return macros[name]

    # Recursively loads partials asynchronously by discovering dependencies then fetching in batch.
    includes = (tpl, vars, cb) ->

        return false if not (tpl and vars)
        if not cb
            cb = vars
            vars = {}

        parts = []

        hasParts = partial.exec(tpl.t)

        # Process while we still have partials to consider.
        while hasParts
            [match, name] = hasParts
            parts.push(name)

            hasParts = partial.exec(tpl.t)

        # If we're not done, load partials asynchronously and continue from there.
        if parts.length
            tpl.load parts, (partials) ->

                src = tpl.t
                tpl.t = src.replace partial, (_, name) ->

                    if partials[name]
                        part = partials[name]

                        return part.t if not extend.test(part.t)

                        e = new Error('[t+]: Invalid include: ' + name + '. Includes may not contain extend blocks.')
                        return cb and cb(false, e)

                    else return _

                return includes(tpl, vars, cb)

        # Otherwise no partials remain. Good job!
        else 
            tpl.parsed = tpl.t
            return parse(tpl, vars, false, cb)

    # Asynchronously & recursively parses string `tpl.t` until finished, then calls `cb` with the resulting `html`.
    parse = (tpl, vars, refresh, cb) ->

        # Save a reference to restore post-parse. We have to manipulate `tpl.t` in order to utilize the original `t` rendering engine, so we restore the original unparsed copy at the end.
        src = tpl.t

        # If dependencies have changed, pass `refresh` as `true` to reparse and recache child templates.
        if refresh or not tpl.parsed

            tpl.parsed = null

            # Check if `tpl` is extending anything, and pass to partial processor if not.
            hasParent = extend.exec(src)
            return includes(tpl, vars, cb) if not hasParent

            # Otherwise load `parent` template and replace named `blocks` with `_blocks` from the child template, then process partials.
            [match, name, rest] = hasParent
            return tpl.load name, (parent) ->

                tpl.t = parent.t
                _blocks = {}

                hasBlocks = blocks.exec(src)
                while hasBlocks
                    [match, tag, name, content] = hasBlocks
                    _blocks[name] = content
                    hasBlocks = blocks.exec(src)

                tpl.t = tpl.t.replace blocks, (_, __, $name, inner) ->
                    return _blocks[$name] or inner

                return includes(tpl, vars, cb)

        # If nothing has changed, we can use the cached, fully-parsed string template.
        else
            tpl.t = tpl.parsed

        # Here's where we pass off to `t`'s rendering engine, and we process for `macro`s on the result.
        html = render.call(tpl, vars).replace macro, (_, __, name, params, content) ->
            params = trim(params.split(','))
            content = content or ''

            m = tpl.macro(name)
            if m
                args = []
                args.push(vars[param]) for param in params
                try return m.apply(null, args)
                catch e
                    console.log('[t+] Macro error:', e)

            else console.log('[t+] No macro found:', name)
            return content


        # Restore the original, unparsed template and trigger callback `cb` with the new `html`.
        tpl.t = src

        cb and cb(html)

    # Loads a template by `name` and passes it to `callback`. To use a different storage system, just overwrite this method and the one below, both on `t` class and on `t::prototype`, conforming to the spec discussed [above](#).
    t.load = t::load = (name, callback) ->
        return load(name, null, callback)

    # Puts a template `tpl` by `name`. `callback` is optional. Overwrite this to customize storage.
    t.put = t::put = (name, tpl, callback) ->
        return load(name, tpl, callback)

    # Registers a macro and returns the macro function by `name`
    t.macro = t::macro = (name, fn) ->
        return macro(name, fn)

    # Our new version of `render`. Pass template context `vars`, a `callback` expecting parsed HTML, and an optional boolean `refresh` to indicate whether to use the interpreted templates cache or parse anew.
    t::render = (vars, callback, refresh=false) ->
        return parse(@, vars, refresh, callback)

    # Return our template class, now on (just a little) steroids.
    return t










