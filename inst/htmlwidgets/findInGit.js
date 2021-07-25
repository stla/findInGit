HTMLWidgets.widget({

  name: "findInGit",

  type: "output",

  factory: function(el, width, height) {

    var ANSItoHTML = require('ansi-to-html');
    console.log("ANSItoHTML", ANSItoHTML);

    return {

      renderValue: function (x) {
        var convert = new ANSItoHTML({
          fg: "#FFF",
          bg: "#000",
          newline: true,
          escapeXML: true,
          stream: false
        });
        var html = convert.toHtml(x.ansi);
        console.log("ansi", x.ansi);
        console.log("html", html);
        el.innerHTML = html;
      },

      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
      }

    };
  }
});
