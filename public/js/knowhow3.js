(function(){
    

})();


jQuery(function($) {
    $(document).ready(function() {

        $('#search').click(function(){
            mainSearch();
        });

        $('#submit').click(function(){
            var knowledge = {};
            knowledge.know = $('#know').val();
            knowledge.how = $('#how').val();
            knowledge.example = $('#example').val();
            $('#myModal').modal('hide');
            if (knowledge.know.length > 80 || knowledge.how.length > 80 || knowledge.example.length > 500 ){ 
                alert("Over maximum words. Please get point and submit");
            } else if(knowledge.know.length == 0 || knowledge.how.length == 0 || knowledge.example.length == 0){
                alert("It has empty content. Please put some");
            }else {
                $.post('/submit', knowledge, function(res){
                    if (res == 'error'){
                        alert("Failed to insert. Please contact admin");
                    }else {
                        alert("Thank you for sharing with us!");
                        location.href = "/knowhow/" + res;
                    }
                });
            }
        });

        $("#search_text").keyup(function(event){
            if(event.keyCode == 13){
                mainSearch();
            }
        });

        $("#delete").click(function(){
            $(this).addClass('disabled');
            if(window.confirm('Are you sure to delete this knowhow?')){
                var record_id = $(this).val();
                $.ajax({
                    url: '/knowhow/delete',
                    type: 'DELETE',
                    data: { id : record_id },
                    success: function(res){
                        //alert(res);
                        location.href = "/";
                    }
                }); 

            }else {
                $(this).removeClass('disabled');
            }
        });

        $(".taglink").click(function(){
            var link = $(this).attr('href');
            $.get(link, function(res){
                //console.log(res);
                var result ="";
                result += '<div class="span3"></div><div class="span6">';
                for (var i in res ){
                  result += '<a href="/knowhow/' + i + '" >' + res[i] + '</a><hr>';
                }
                result += '</div><div class="span3"></div>';
                //console.log(result);
                $("#page_info").html('');
                $("#view").html(result);
            });
            return false;
        });

        $("#add_knowhow").click(function(){
            var value = $(this).attr('value');
            $.post('/knowhow/mine', {id : value, method : 'add'}, function(res){
                alert(res);
                window.location.reload();
            });
        });

        $("#remove_knowhow").click(function(){
            var value = $(this).attr('value');
            $.post('/knowhow/mine', {id : value, method : 'remove'}, function(res){
                alert(res);
                window.location.reload();
            });
        });

        $(countWords('textarea#know', '#know_count', 80));
        $(countWords('textarea#how', '#how_count', 80));
        $(countWords('textarea#example', '#example_count', 500));
    });

    function countWords(textarea_id, count_id, countMax){
        $(textarea_id).bind('keydown keyup keypress change',function(){
            var thisValueLength = $(this).val().length;
            var countDown = (countMax)-(thisValueLength);
            $(count_id).html(countDown);
            if(countDown < 5){
                $(count_id).css({color:'#ee2b2b',fontWeight:'bold'});
            } else if (countDown < 10){
                $(count_id).css({color:'#eeee2b',fontWeight:'bold'});
            } else {
                $(count_id).css({color: '#ffb39c' ,fontWeight:'normal'});
            }
        });
        $(window).load(function(){
            $(count_id).html(countMax);
        });
    }

    function mainSearch() {
        var search = {}
        search.query = $('#search_text').val();
        search.know = 0;
        search.how = 0;
        search.example = 0;
        $("input[name=check]:checked").map(function(){
            var v = $(this).val();
            if (v == 'know') {
                search.know = 1;
            }else if ( v == 'how' ) {
                search.how = 1;
            }else if ( v == 'example' ) {
                search.example = 1;
            }
        });
        //console.log(search);
        $.post('/search', search, function(res){
            //console.log(res);
            var result ="";
            result += '<div class="span3"></div><div class="span6">';
            if (res === "" ){
                result = "<center><strong>No Search Result</strong></center><br><br><br>";
            }else {
                for (var i in res ){
                  result += '<a href="/knowhow/' + i + '" >' + res[i] + '</a><hr>';
                }
            }
            result += '</div><div class="span3"></div>';
            //console.log(result);
            $("#page_info").html('');
            $("#view").html(result);
        });
    }

});
            
