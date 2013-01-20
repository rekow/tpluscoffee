// Generated by CoffeeScript 1.4.0

/*

     _      _            __  __
    | |_  _| |_  __ ___ / _|/ _|___ ___
    |  _||_   _|/ _/ _ \  _|  _/ -_) -_)
     \__|  |_|(_)__\___/_| |_| \___\___|

  t+.coffee - extends t.js with compilation, named blocks,
              includes and extends via simple template loading.

  @author  David Rekow <david at davidrekow.com>
  @license MIT
  @version 0.0.1
*/


(function() {
  var t;

  t = this.t;

  this.t = (function(t) {
    var blocks, extend, include, macro, macros, parse, preprocess, render, templates, trim, triml, trimr, _render;
    include = /\{\{\s*?\&\s*?([^\s]+?)\s*?\}\}/g;
    extend = /^\{\{\s*?\^\s*?([^\s]+?)\s*?\}\}([.\s\S]*)/g;
    macro = /\{\{\s*?\+\s*?([^\(]+)\(([^\)]+)\)\s*?\}\}/;
    blocks = /\{\{\s*?(\$\s*?([^\s]+?))\}\}([\s\S.]+)\{\{\s*?\/\s*?(?:\1|\2)\}\}/g;
    triml = /^\s+/;
    trimr = /\s+$/;
    templates = {};
    macros = {};
    _render = t.prototype.render;
    trim = function(str) {
      return str.replace(triml, '').replace(trimr, '');
    };
    parse = function(tpl, vars) {
      var html, _t;
      _t = tpl.t;
      html = _render.call(preprocess(tpl, vars), vars);
      tpl.t = _t;
      return html;
    };
    preprocess = function(tpl, vars) {
      var src;
      src = tpl.t;
      tpl.t = src.replace(extend, function(_, name, rest) {
        var parent, _blocks;
        _blocks = {};
        parent = tpl.load(name);
        if (parent) {
          rest.replace(blocks, function(_, __, name, inner) {
            _blocks[name] = inner;
            return _;
          });
          return parent.t.replace(blocks, function(_, __, name, _default) {
            var block;
            block = _blocks[name];
            delete _blocks[name];
            return block || _default;
          });
        } else {
          return rest.replace(blocks, function(_, __, name, inner) {
            return inner;
          });
        }
      }).replace(include, function(_, name) {
        var child;
        child = tpl.load(name);
        return child.t || '';
      }).replace(macro, function(_, name, params) {
        var param, _i, _len, _macro, _params;
        _params = params.split(',');
        params = [];
        for (_i = 0, _len = _params.length; _i < _len; _i++) {
          param = _params[_i];
          params.push(vars[trim(param)]);
        }
        _macro = macros[name];
        if (_macro) {
          return _macro.apply(null, params);
        } else {
          return '';
        }
      });
      return (include.test(tpl.t) || macro.test(tpl.t) ? preprocess(tpl, vars) : tpl);
    };
    render = function(html, tpl) {
      var el, env, newEl;
      el = tpl._element;
      if (!el) {
        return html;
      }
      env = document.createElement('div');
      env.appendChild(el.cloneNode(false));
      env.firstChild.outerHTML = html;
      tpl._element = newEl = env.firstChild;
      tpl._previousElement = el.parentNode.replaceChild(newEl, el);
      return tpl;
    };
    t.prototype.bind = function(el) {
      if (el && el.nodeType) {
        this._element = el;
      }
      this._previousElement = null;
      return this;
    };
    t.prototype.load = function(name) {
      return templates[name];
    };
    t.prototype.macro = function(name, fn) {
      if (fn) {
        macros[name] = fn;
      }
      return macros[name];
    };
    t.prototype.parse = function(vars) {
      return parse(this, vars);
    };
    t.prototype.register = function(name, tpl) {
      tpl = tpl.t ? tpl : new this.constructor(tpl);
      templates[name] = tpl;
      return tpl;
    };
    t.prototype.render = function(vars) {
      var html;
      html = vars.charAt ? vars : this.parse(vars);
      return render(html, this);
    };
    t.prototype.undo = function() {
      return this.render(this._previousElement.outerHTML);
    };
    return t;
  })(t);

}).call(this);