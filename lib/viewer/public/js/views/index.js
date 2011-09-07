App.Views.Video = Backbone.View.extend({
    initialize: function() {
        //this.documents = this.options.documents;
        this.render();
    },
    
    render: function() {
				var out = "";
        $(this.el).html(out);
        $('#app').html(this.el);
    }
});