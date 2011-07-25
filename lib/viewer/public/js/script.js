$(function(){
	$('.rmv-dft-val').click(
		function() {
			if (this.value == this.defaultValue) {
				this.value = '';
			}
		}
	);
	$('.rmv-dft-val').blur(
		function() {
			if (this.value == '') {
				this.value = this.defaultValue;
			}
	}
	);

	$("#invite-email").bind('keyup', function() {
		if(validateEmail($(this).val())){
			$('#invite-submit').removeAttr('disabled');
		}else{
			$('#invite-submit').attr('disabled', 'disabled');		
		}
	});

	$('#invite-form').bind('submit', function(e){
    $('.after_submit').hide();
		var params = $(this).serialize();
		var $email = $("#invite-email").val();
		if(validateEmail($email)){
			mpmetrics.register( { email_input : $email} );
			$.ajax({
		    type: "POST",
		    url: $('#invite-form').attr('action'),
		    data: params,
        dataType: 'jsonp',
        jsonp: 'callback',
        jsonpCallback: function(r){
        },
		    success: function(r) {
		    	console.log('yay', r);
		    	$('#invite-form').hide();
		      //display message back to user here
		      $('#ref_share .fblike').html('<fb:like href="'+r.reflink+'" send="true" layout="button_count" width="90" show_faces="false" action="recommend"></fb:like>');
		      

		      var tweet_text = encodeURIComponent("Want to see the future of video entertainment? Join me for the #nowmovapp launch.");
		      $('#ref_share .tweet').html('<iframe allowtransparency="true" frameborder="0" scrolling="no" src="http://platform.twitter.com/widgets/tweet_button.html?url='+r.reflink+'&via=nowmov&related=fahdoo:Nowmov UX Engineer&text='+tweet_text+'" style="width:130px; height:20px;"></iframe>');

        
		     	$('#ref_share .plusone').html('<g:plusone href="'+r.reflink+'" size="medium"></g:plusone>');
		     	
		     	FB.XFBML.parse(document.getElementById('ref_share'));
		     	gapi.plusone.go(document.getElementById('ref_share'));
		     		
		     	$('#referral_link').val(r.reflink);
		     			      		       
					$('#post_success').show();

		      mpmetrics.track('Submit Success', r);
		    },
		    error: function(r){
		      mpmetrics.track('Submit Fail', r);
		    	console.log('nay', r);
		    	//$('#invite-form').hide(); 
		    	$('#post_fail').show();
		    }
		  });
		}

	  e.preventDefault();
		return false;
	});
	
	function validateEmail($email) {
		var emailReg = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
		if( !emailReg.test( $email ) ) {
			return false;
		} else {
			return true;
		}
	}
	
});