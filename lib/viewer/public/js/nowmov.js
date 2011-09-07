var App = {
    Views: {},
    Controllers: {},
    Collections: {},
    init: function() {
        new App.Controllers.Videos();
        Backbone.history.start();
    }
};

$(function(){
   App.init();	
});