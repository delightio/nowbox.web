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
		var params = $(this).serialize();
		if(validateEmail($("#invite-email").val())){
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
		      //display message back to user here
		      $('#invite-form').hide(); 
		      $('#post_invite').show();
		      mpmetrics.track('Submit Success', r);
		    },
		    error: function(r){
		      mpmetrics.track('Submit Fail', r);
		    	console.log('nay', r);
		    	$('#invite-form').hide(); 
		    	$('#fail_invite').show();
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