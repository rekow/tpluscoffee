# t+.coffee
## t.coffee, on steroids.

[`t.js`](http://www.github.com/jasonmoo/t.js) is a simple solution to interpolating values in an html string for insertion into the DOM via `innerHTML`.

 [`t.coffee`](http://www.github.com/davidrekow/t.coffee) ports that simplicity to coffeescript, adding scoped iteration for concise, readable templates.

 [`t+.coffee`](http://www.github.com/davidrekow/t-coffee) is the [`Handlebars`](https://github.com/wycats/handlebars.js) to [`t.coffee`](http://www.github.com/davidrekow/t.coffee)'s [`Mustache`](http://mustache.github.com/).

### Features
`t.js`

 * Simple interpolation: `{{=value}}`
 * Scrubbed interpolation: `{{%unsafe_value}}`
 * Name-spaced variables: `{{=User.address.city}}`
 * If/else blocks: `{{value}} <<markup>> {{:value}} <<alternate markup>> {{/value}}`
 * If not blocks: `{{!value}} <<markup>> {{/value}}`
 * Simple object/array iteration: `{{@obj}}{{=_key}}:{{=_val}}{{/object}}`'
 * Multi-line templates (no removal of newlines required to render)
 * Render the same template multiple times with different data
 * Works in all modern browsers

`t.coffee`

 * Scoped object/array iteration: `{{>obj}}{{=name}}, {{=age}}, {{=city}} {{/obj}}`
 * Space-agnostic parsing `{{=var}}` or `{{= var }}`

`t+.coffee`

 * Macros: `{{+macro(param1, param2...)}}`, must be registered first: `t.macro(name, fn)`
 * Includes/partials: `{{&partial}}`
 * Extends, with named blocks: `{{^parentTemplate}}{{$block1}}content{{/$block1}}, {{$block2}}content 2{{$/block}}`
   * Caveat: extend block must be first block in template
 * Simple template management via `t.register(name, stringTemplateOrT)` and `t.load(name)`
 * Optional DOM binding/insertion: `t.bind(element); t.render(vars);` -> updates `element` at `t._element` and caches previous element at `t._previousElement`
   * Single-step rollback using `t.undo()`

Coming soon:
 * Template-to-function compilation, pre-deploy or at runtime

### How to use

Compile to JS as you normally would. You can also use the included Cakefile:

    $ cake compile (-s/--source [SOURCEDIR]) (-o/--output [OUTPUTDIR])

Then use just like [`t.js`](http://www.github.com/jasonmoo/t.js):

    var template = new t("<div>Hello {{=name}}</div>");
    document.body.innerHTML = template.render({name: "World!"});

For more advanced usage check the `t_test.html`.

This software is released under the MIT license.