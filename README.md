# t+.coffee
## t.coffee, on steroids.

Check out [the docs](http://davidrekow.github.com/tpluscoffee).

### How to use

Compile to JS as you normally would. You can also use the included Cakefile:

    $ cake compile (-s/--source [SOURCEDIR]) (-o/--output [OUTPUTDIR])

Then use just like [`t.js`](http://www.github.com/jasonmoo/t.js):

    var template = new t("<div>Hello {{=name}}</div>");
    document.body.innerHTML = template.render({name: "World!"});

This software is released under the MIT license.
