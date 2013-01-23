# t+.coffee
## t.coffee, on steroids.

[`t.js`](http://www.github.com/jasonmoo/t.js) is a simple solution to interpolating values in an html string for insertion into the DOM via `innerHTML`.

 [`t.coffee`](http://www.github.com/davidrekow/t.coffee) ports that simplicity to coffeescript, adding scoped iteration for concise, readable templates.

 `t+` is the [`Handlebars`](https://github.com/wycats/handlebars.js) to `t`'s [`Mustache`](http://mustache.github.com/).

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

 * Partials & inheritance
   * Include: `{{&<name>}}`.
   * Extend, replacing named blocks: `{{^parent}}{{#block1}}content{{/block1}}{{#block2}}content 2{{/block2}}`
     * Extend block `{{^<name>}}` must be first block in template
     * Content between blocks in child template will be ignored
   * Interpreted templates cached for fast re-render
 * Simple template management via `t.register(name, stringTemplateOrT)` and `t.load(name)`
   * Extensible - simply overwrite `t.register` & `t.load` with your own logic and return an instance of `t`
   * Register functions should expect `(name, stringTemplateOrT)`, while loader functions should accept `name`
 * Optional DOM hooks
   * Bind to an element: `t.bind(el)`. Updates `el` at `t._element` and stores previous element at `t._previousElement`
     * Pre- and post-DOM-insert hooks: `t.setPrerender()` & `t.setPostrender()`. Prerender is handed `(el, html, callback)`, while postrender receives `el`.
 * Macros
   * Inline: `{{+<name>(param1, param2)}}`. If an error occurs, returns `''`.
   * Block: `{{+<name>(param1, param2...)}} <default content> {{/<name>}}`. If an error occurs, returns `<default content>`.
   * Must be registered first: `t.macro(name, fn)`.


Coming soon:

 * Template-to-function compilation, pre-deploy or at runtime

### How to use

Compile to JS as you normally would. You can also use the included Cakefile:

    $ cake compile (-s/--source [SOURCEDIR]) (-o/--output [OUTPUTDIR])

Then use just like [`t.js`](http://www.github.com/jasonmoo/t.js):

    var template = new t("<div>Hello {{=name}}</div>");
    document.body.innerHTML = template.render({name: "World!"});

This software is released under the MIT license.