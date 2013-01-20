###

     _      _            __  __
    | |_  _| |_  __ ___ / _|/ _|___ ___
    |  _||_   _|/ _/ _ \  _|  _/ -_) -_)
     \__|  |_|(_)__\___/_| |_| \___\___|

  t+.coffee - extends t.js with compilation, named blocks,
              includes and extends via simple template loading.

  @author  David Rekow <david at davidrekow.com>
  @license MIT
  @version 0.0.2
###
t = @t
@t = do (t) ->

  include = /\{\{\s*?\&\s*?([^\s]+?)\s*?\}\}/g
  extend = /^\{\{\s*?\^\s*?([^\s]+?)\s*?\}\}([.\s\S]*)/g
  macro = /\{\{\s*?\+\s*?([^\(]+)\(([^\)]+)\)\s*?\}\}/g
  blocks = /\{\{\s*?(\$\s*?([^\(]+){1})([\w\s,\(\)]*)\s*?\}\}([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\}/g

  triml = /^\s+/
  trimr = /\s+$/

  templates = {}
  macros = {}

  _render = t::render

  load = register = null
  t::customLoader = false
  t::customRegister = false

  toMacro = (vars, params='', inner) ->
    if params.charAt(0) is '(' and params.charAt(params.length-1) is ')'
      params = params.slice(1, params.length-1)
    params = trim(params.split(','))
    name = params.shift()

    # add default content callable
    id = btoa((+new Date).toString(16))
    vars[id] = ->
      return inner
    params.push(id)

    return '{{+' + name + '(' + params.join(',') + ')}}'

  trim = (str) ->
    if str.charAt
      str = str.replace(triml, '').replace(trimr, '')
    else if str.length
      str[i] = trim(s) for s, i in str
    return str

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
        rest.replace blocks, (_, __, name, params, inner) ->
          return toMacro(vars, params, inner) if name is 'call'
          _blocks[name] = inner
          return _

        return parent.t.replace blocks, (_, __, name, params, _default) ->
          return toMacro(vars, params, _default) if name is 'call'
          block = _blocks[name]
          delete _blocks[name]
          return block or _default

      else return rest.replace blocks, (_, __, name, params, inner) ->
        return (if name is 'call' then toMacro(vars, params, inner) else inner)

    .replace include, (_, name) ->
      child = tpl.load(name)
      return child.t or ''

    .replace macro, (_, name, params) ->
      _params = params.split(',')
      params = []
      for param in _params
        params.push(vars[trim(param)])

      _macro = macros[name]
      _def = params.pop()

      if _macro
        try return _macro.apply(null, params)
        catch e
          console.error(e)
      if _def and typeof _def is 'function'
        return _def()
      return ''

    return (if include.test(tpl.t) or macro.test(tpl.t) then preprocess(tpl, vars) else tpl)

  compile = (tpl) ->
    return tpl

  render = (html, tpl) ->
    el = tpl._element
    return html if not el

    env = document.createElement('div')
    env.appendChild(el.cloneNode(false))
    env.firstChild.outerHTML = html

    tpl._element = newEl = env.firstChild
    tpl._previousElement = el.parentNode.replaceChild(newEl, el)

    return tpl

  setLoader = (fn) ->
    if fn and typeof fn is 'function'
      load = t::load
      t::load = fn
      t::customLoader = true
    return

  setRegister = (fn) ->
    if fn and typeof fn is 'function'
      register = t::register
      t::register = fn
      t::customRegister = true
      if templates
        new t('').register(templates)
        templates = false
    return

  t::load = (name) ->
    return templates[name]

  t::setLoader = (fn) ->
    setLoader(fn)
    return @

  t::register = (name, tpl) ->
    tpl = if tpl.t then tpl else new @constructor(tpl)
    templates[name] = tpl
    return tpl

  t::setRegister = (fn) ->
    setRegister(fn)
    return @

  t::bind = (el) ->
    @_element = el if el and el.nodeType
    @_previousElement = null
    return @

  t::parse = (vars) ->
    return parse @, vars

  t::render = (vars) ->
    html = if vars.charAt then vars else @parse(vars)
    return render(html, @)

  t::undo = () ->
    @render(@_previousElement.outerHTML) if @_previousElement

  t::macro = (name, fn) ->
    macros[name] = fn if fn
    return macros[name]

  return t