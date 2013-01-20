###

     _      _            __  __
    | |_  _| |_  __ ___ / _|/ _|___ ___
    |  _||_   _|/ _/ _ \  _|  _/ -_) -_)
     \__|  |_|(_)__\___/_| |_| \___\___|

  t+.coffee - extends t.js with compilation, named blocks,
              includes and extends via simple template loading.

  @author  David Rekow <david at davidrekow.com>
  @license MIT
  @version 0.0.1
###
t = @t
@t = do (t) ->

  include = /\{\{\s*?\&\s*?([^\s]+?)\s*?\}\}/g
  extend = /^\{\{\s*?\^\s*?([^\s]+?)\s*?\}\}([.\s\S]*)/g
  macro = /\{\{\s*?\+\s*?([^\(]+)\(([^\)]+)\)\s*?\}\}/
  blocks = /\{\{\s*?(\$\s*?([^\s]+?))\}\}([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\}/g

  triml = /^\s+/
  trimr = /\s+$/

  templates = {}
  macros = {}

  _render = t::render

  trim = (str) ->
    return str.replace(triml, '').replace(trimr, '')

  parse = (tpl, vars) ->
    _t = tpl.t
    html = _render.call(preprocess(tpl, vars), vars)
    tpl.t = _t

    return html

  preprocess = (tpl, vars) ->
    src = tpl.t

    tpl.t = src.replace extend, (_, name, rest) ->
      _blocks = {}
      parent = tpl.load(name)

      if parent
        rest.replace blocks, (_, __, name, inner) ->
          _blocks[name] = inner
          return _

        return parent.t.replace blocks, (_, __, name, _default) ->
          block = _blocks[name]
          delete _blocks[name]
          return block or _default

      else
        return rest.replace blocks, (_, __, name, inner) ->
          return inner

    .replace include, (_, name) ->
      child = tpl.load(name)
      return child.t or ''

    .replace macro, (_, name, params) ->
      _params = params.split(',')
      params = []
      for param in _params
        params.push(vars[trim(param)])

      _macro = macros[name]
      return if _macro then _macro.apply(null, params) else ''

    return (if include.test(tpl.t) or macro.test(tpl.t) then preprocess(tpl, vars) else tpl)

  render = (html, tpl) ->
    el = tpl._element
    return html if not el

    env = document.createElement('div')
    env.appendChild(el.cloneNode(false))
    env.firstChild.outerHTML = html

    tpl._element = newEl = env.firstChild
    tpl._previousElement = el.parentNode.replaceChild(newEl, el)

    return tpl

  t::bind = (el) ->
    @_element = el if el and el.nodeType
    @_previousElement = null
    return @

  t::load = (name) ->
    return templates[name]

  t::macro = (name, fn) ->
    macros[name] = fn if fn
    return macros[name]

  t::parse = (vars) ->
    return parse @, vars

  t::register = (name, tpl) ->
    tpl = if tpl.t then tpl else new @constructor(tpl)
    templates[name] = tpl
    return tpl

  t::render = (vars) ->
    html = if vars.charAt then vars else @parse(vars)
    return render(html, @)

  t::undo = () ->
    @render(@_previousElement.outerHTML) if @_previousElement

  return t