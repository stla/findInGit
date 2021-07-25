HTMLWidgets.widget({

  name: "findInGit",

  type: "output",

  factory: function(el, width, height) {

    var ANSItoHTML = require('ansi-to-html');

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
        var lines = html.split("<br/>");
        for(var i = 0; i < lines.length; i++){
          lines[i] = lines[i]
            .replace("BRANCH~~", '<span style="color:yellow;">~')
            .replace("~~", '~</span>');
        }
        html = lines.join("<br/>");
        el.innerHTML = html;
      },

      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
      }

    };
  }
});
