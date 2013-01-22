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
  t.noConflict = -> (t = _t; _t)

  include = /\{\{\s*?\&\s*?([^\s]+?)\s*?\}\}/g
  extend = /^\{\{\s*?\^\s*?([^\s]+?)\s*?\}\}([.\s\S]*)/g
  _macro = /\{\{\s*?(\+\s*?([^\(]+))\(([^\)]*)\)?\s*?\}\}(?:([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\})?/g
  blocks = /\{\{\s*?(\$\s*?([\w]+))\s*?\}\}([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\}/g

  string = (item) ->
    return ({}).toString.call(item)

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

  _render = t::render
  parse = (tpl, vars) ->
    __t = tpl.t
    html = _render.call(preprocess(tpl, vars), vars)
    tpl.t = __t
    return html

  preprocess = (tpl, vars) ->
    src = tpl.t
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

    .replace include, (_, name) ->
      child = tpl.load(name)
      return child.t or ''

    .replace _macro, (_, __, name, params, content) ->
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

    return (if include.test(tpl.t) or _macro.test(tpl.t) then preprocess(tpl, vars) else tpl)

  render = (html, tpl) ->
    el = tpl._element
    return html if not el

    tpl = tpl.preRender(el, html)

    env = document.createElement('div')
    env.appendChild(el.cloneNode(false))
    env.firstChild.outerHTML = html

    tpl._element = newEl = env.firstChild
    tpl._previousElement = el.parentNode.replaceChild(newEl, el)

    tpl = tpl.postRender(el, html)
    return tpl

  t.templates = ->
    return load()

  t.load = (name) ->
    return load(name)

  t.register = (name, tpl) ->
    return load(name, tpl)

  t.macro = (name, fn) ->
    return macro(name, fn)

  t.setPrerender = (fn) ->
    t::prerender = fn if fn and typeof fn is 'function'

  t.setPostrender = (fn) ->
    t::postrender = fn if fn and typeof fn is 'function'

  t::load = (name) ->
    return t.load(name)

  t::register = (name, tpl) ->
    return t.register(name, tpl)

  t::bind = (el) ->
    @_element = el if el and el.nodeType
    @_previousElement = null
    return @

  t::parse = (vars) ->
    return parse @, vars

  t::render = (vars) ->
    vars = vars or {}
    html = if vars.charAt then vars else @parse(vars)
    return render html, @

  t::prerender = (el, html, tpl) -> tpl
  t::postrender = (el, html, tpl) -> tpl

  t::setPrerender = (fn) ->
    if fn and typeof fn is 'function'
      @prerender = () =>
        return fn.apply @, arguments
  t::setPostrender = (fn) ->
    if fn and typeof fn is 'function'
      @prerender = () =>
        return fn.apply @, arguments

  t::undo = () ->
    @render(@_previousElement.outerHTML) if @_previousElement

  t::macro = (name, fn) ->
    return t.macro(name, fn)

  return t
