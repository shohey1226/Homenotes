(function(){

    //=========================================================================
    // To avoid the conflict with Mojolicious's template
    //=========================================================================
    // _.templateSettings = {
    //     evaluate: /\{\{([\s\S]+?)\}\}/g,
    //     interpolate: /\{\{=([\s\S]+?)\}\}/g
    // };

    //=========================================================================
    // To submit knowhow 
    //=========================================================================
    // knowhow model for submittion
    var Knowhow = Backbone.Model.extend({
        url: '/submit',
        defaults: {
            know : '',
            how : '',
            example : ''
        },
        validate: function(attrs){
            if (attrs.know.length > 80 || attrs.how.length > 80 || attrs.example.length > 500 ){ 
                return "Over maximum words. Please get point and submit";
            } else if(attrs.know.length == 0 || attrs.how.length == 0 || attrs.example.length == 0){
                return "It has empty content. Please put some";
            }
        }
    });

    // String counters on submit modal 
    var CountersView = Backbone.View.extend({
        tagName: 'span',
        className: 'count',
        initialize: function(){
            _.bindAll(this, 'count');
            _.bindAll(this, 'render');
            for (var i = 0, l = this.collection.length; i < l; i++) {
                this.render('#' + this.collection.models[i].get('name') + '_count', this.collection.models[i].get('max'));
                var selector = 'textarea#' + this.collection.models[i].get('name');
                $(selector).on("keydown keyup keypress change", 
                                _.bind(this.count, this, {selector: selector, model: this.collection.models[i]}));
            }
        },
        count: function(my){
            var thisValueLength = $(my.selector).val().length;
            var countMax = my.model.get('max');
            var countDown = (countMax)-(thisValueLength);
            var id = '#' + my.model.get('name') + '_count';
            this.render(id, countDown);
        },
        render: function(id, countDown) {
            $(id).html(countDown);
            if(countDown < 5){
                $(id).css({color:'#ee2b2b',fontWeight:'bold'});
            } else if (countDown < 10){
                $(id).css({color:'#eeee2b',fontWeight:'bold'});
            } else {
                $(id).css({color: '#ffb39c' ,fontWeight:'normal'});
            }
        }
    });

    // Counter instance with Knowhow model    
    Counters = Backbone.Collection.extend({model: Knowhow});
    counters = new Counters([ 
        {name: 'know', counter:0, max: 80},
        {name: 'how', counter:0, max: 80},
        {name: 'example', counter:0, max: 500},
    ]);

    // View for sumbittion of knowhow
    var ModalFooterView = Backbone.View.extend({
        tagName: 'div',
        className: 'modal-footer',
        events: {
            'click #submit': 'submitKnowhow'
        },
        submitKnowhow: function() {
            this.model.save(
                {
                    know: $('#know').val(),
                    how: $('#how').val(),
                    example: $('#example').val()
                }, 
                {   
                    success: function(model, response){
                        if (response == 'error'){
                            alert("Failed to insert. Please contact admin");
                        }else {
                            alert("Thank you for sharing with us!");
                            location.href = "/knowhow/view/" + response;
                            //router.navigate("/knowhow/view/" + response);
                        }
                    }
                }
            );
        },
        render: function (){
            this.$el.append('<button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>');
            this.$el.append('<button id="submit" class="btn btn-warning">Submit your knowhow!</button>');
            return this;
        }
    });

    var knowhow = new Knowhow(); // for submition
    coutersview = new CountersView({collection: counters});
    knowhow.on("invalid", function(model, error) { alert(error) }); // handles validation
    var modalfooter = new ModalFooterView({model: knowhow});
    $('#myModal').append(modalfooter.render().el);

    //=========================================================================
    // To show knowhow 
    //=========================================================================
    var KnowhowResult = Backbone.Model.extend({
        urlRoot: '/knowhow'
    });
    var KnowhowResultView = Backbone.View.extend({
        template: _.template("<h2>KNOW</h2><pre><code><%- know %></code></pre><h2>HOW</h2><h2>EXAMPLE</h2>"),
        render: function(){
            var html = this.template(this.model.toJSON());
            console.log(html);
            $('#view').html(html);
        }
    });
    
    
    //=========================================================================
    // Router 
    //=========================================================================
    var HomenotesRouter = Backbone.Router.extend({
        routes: {
            "knowhow/view/:id": "knowhow",
            "": 'top',
        },
        "knowhow": function(id){
            alert(id);
            var knowhow = new KnowhowResult({id : id});
            knowhow.fetch({
                success: function(res) {
                    console.log(knowhow.toJSON());
                    var knowhowview = new KnowhowResultView({model: knowhow});
                    knowhowview.render();
                }
            });

        },
        'top': function(id){
            console.log('top');
        }
    }); 
    var router = new HomenotesRouter();
    Backbone.history.start({ pushState: true });


        
})();
