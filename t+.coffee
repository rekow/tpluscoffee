###

     _      _            __  __
    | |_  _| |_  __ ___ / _|/ _|___ ___
    |  _||_   _|/ _/ _ \  _|  _/ -_) -_)
     \__|  |_|(_)__\___/_| |_| \___\___|

  t+.coffee - extends t.js with compilation, named blocks,
              includes and extends via simple template loading.

  @author  David Rekow <david at davidrekow.com>
  @license MIT
  @version 0.0.3
###
t = @t
@t = do (t) ->

  _t = t
  render = t::render

  t.noConflict = -> (t = _t; _t)

  partial = /\{\{\s*?\&\s*?([^\s]+?)\s*?\}\}/g
  extend = /^\{\{\s*?\^\s*?([^\s]+?)\s*?\}\}([.\s\S]*)/g
  _macro = /\{\{\s*?(\+\s*?([^\(]+))\(([^\)]*)\)\s*?\}\}(?:([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\})?/g
  blocks = /\{\{\s*?(#\s*?([\w]+))\s*?\}\}([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\}/g

  triml = /^\s+/
  trimr = /\s+$/
  trim = (str) ->
    if str.charAt
      str = str.replace(triml, '').replace(trimr, '')
    else if str.length
      str[i] = trim(s) for s, i in str
    return str

  templates = {}
  load = (name, tpl) ->
    return templates if not name
    if typeof name is 'object'
      load(_name, _tpl) for _name, _tpl of name
      return true

    if tpl and (tpl.t or tpl.charAt)
      tpl = tpl.t or new t(tpl)
      tpl.name = name
      templates[name] = tpl

    return templates[name]

  macros = {}
  macro = (name, fn, ctx) ->
    return macros if not name
    ctx = ctx or null
    if typeof name is 'object'
      ctx = fn or ctx
      macro(_name, _fn, ctx) for _name, _fn of name
      return true

    if fn and typeof fn is 'function'
      macros[name] = () ->
        return fn.apply(ctx, arguments)

    return macros[name]

  include = (tpl) ->
    return tpl.t.replace partial, (_, name) ->
      return include(tpl.load(name))

  parsed = {}
  parse = (tpl, vars) ->
    src = tpl.t

    if parsed[tpl.name]
      tpl.t = parsed[tpl.name]

    else
      tpl.t = src.replace extend, (_, name, rest) ->
        parent = tpl.load(name)
        if parent
          _blocks = {}
          rest.replace blocks, (_, __, $name, inner) ->
            return (_blocks[$name] = inner; _)

          return parent.t.replace blocks, (_, __, $name, _default) ->
            block = _blocks[$name]
            return block or _default

        else return rest.replace blocks, (_, __, $name, inner) ->
          return inner

      parsed[tpl.name] = tpl.t = include(tpl)

    html = render.call(tpl, vars).replace _macro, (_, __, name, params, content) ->
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

    tpl.t = src

    return html if not tpl._element
    el = tpl._element

    return tpl.prerender el, html, ->
      env = document.createElement('div')
      env.appendChild(el.cloneNode(false))
      env.firstChild.outerHTML = html

      tpl._element = newEl = env.firstChild
      tpl._previousElement = el.parentNode.replaceChild(newEl, el)

      return tpl.postrender(el)

  t.load = t::load = (name) ->
    return load(name)

  t.register = t::register = (name, tpl) ->
    return load(name, tpl)

  t.macro = t::macro = (name, fn) ->
    return macro(name, fn)

  t.parsed = (name) ->
    return parsed[name]

  t::bind = (el) ->
    @_element = el if el and el.nodeType
    @_previousElement = null
    return @

  t::render = (vars) ->
    return parse @, vars

  # Fallbacks only to prevent errors.
  # Overwrite with custom logic (animation, etc)
  # at the instance level.
  t::prerender = (el, html, cb) -> cb()
  t::postrender = () ->

  return t
