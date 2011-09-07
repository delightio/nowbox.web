App.Controllers.Videos = Backbone.Controller.extend({
    routes: {
/*         "videos/:id":            "edit", */
        "":                         "index",
/*         "new":                      "newDoc" */
    },
/*
    
    edit: function(id) {
        var doc = new Video({ id: id });
        doc.fetch({
            success: function(model, resp) {
                new App.Views.Edit({ model: doc });
            },
            error: function() {
                new Error({ message: 'Could not find that Video.' });
                window.location.hash = '#';
            }
        });
    },
*/
    
    index: function() {
        $.getJSON('/videos', function(data) {
            if(data) {
                var videos = _(data).map(function(i) { return new Video(i); });
                new App.Views.Index({ videos: videos });
            } else {
                new Error({ message: "Error loading Videos." });
            }
        });
    },
    
/*
    newDoc: function() {
        new App.Views.Edit({ model: new Video() });
    }
*/
});