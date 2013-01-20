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

 * Includes/partials: `{{&partial}}`, rendered in current context
 * Extends, with named blocks: `{{^parentTemplate}}{{$block1}}content{{/block1}} {{$block2}}content 2{{/block2}}`
   * Extend block `{{^<name>}}` must be first block in template
   * Content between blocks will be ignored
 * Simple template management via `t.register(name, stringTemplateOrT)` and `t.load(name)`
   * Can set custom load & register functions to manage templates elsewhere, via `t.setLoader(fn)` and `t.setRegister(fn)`. Register functions should expect incoming `(name, stringTemplateOrT)`, while loader functions should accept a string `name`.
 * Optional DOM binding/insertion: `t.bind(element); t.render(vars);` -> updates `element` at `t._element` and caches previous element at `t._previousElement`
   * Single-step rollback using `t.undo()`
 * Macros two ways
   * Inline: `{{+<name>(param1, param2...)}}`. If an error occurs, returns `''`.
   * `$call` block: `{{$call(<name>, param1, param2)}}<default content>{{/call}}`. If an error occurs, returns `<default content>`.

Macros must be registered first, `t.macro(name, fn)`, and can be used on the fly in JS - but remember, macros should throw an error when invoked incorrectly, so if you're using them outside templates you should wrap in a try/catch:

    # register
    t.macro 'join', (a, b) ->
        throw 'join() requires two parameters.' if not (a and b)
        return a + ' ' + b

    t.macro('join') 'hey'   # throws an error

    try
        t.macro('join') 'hey'
    catch e
        console.log('Join error:', e)   # sweet

Coming soon:
 * Template-to-function compilation, pre-deploy or at runtime

### How to use

Compile to JS as you normally would. You can also use the included Cakefile:

    $ cake compile (-s/--source [SOURCEDIR]) (-o/--output [OUTPUTDIR])

Then use just like [`t.js`](http://www.github.com/jasonmoo/t.js):

    var template = new t("<div>Hello {{=name}}</div>");
    document.body.innerHTML = template.render({name: "World!"});

This software is released under the MIT license.