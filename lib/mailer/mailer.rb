require 'rubygems'
require 'sinatra/base'
require 'pony'

# require_relative 'mailgun/mailgun'

module Aji
  class Mailer < Sinatra::Base
# #     set :raise_errors, false 
# #     set :show_exceptions, true if development? 
# 		Mailgun::init("key-038fp4b9sv6$r3sxa0")    
#     
#     # Use Erubis for template generation. Essentially a faster ERB.
     Tilt.register :erb, Tilt[:erubis]
#     
#     # Need to explicitly set the template directory:
#     # http://stackoverflow.com/questions/3742486/sinatra-cannot-find-views-on-ruby-1-9-2-p0
     set :views, File.dirname(__FILE__) + "/views"
     set :public, File.dirname(__FILE__) + "/public"
# 		  
 
		helpers do
		end
		
		before do
		end
 		
		#########
		# ROUTES
		#########

		get '/test_pony' do
			@sender   = "notifier@nowmov.mailgun.org"
			@receiver = "fahdoo@nowmov.com"
		  Pony.mail(:to=> @receiver, 
		            :from => @sender, 
	              :headers 		=> {'Content-Type' => 'text/html', 'X-Mailgun-Tag' => 'pony_test'},
		            :subject=> "Pony Test Email!",
		            :body => erb(:'test.html'),
		            :via => :smtp, 
		            :via_options => {
		              :address      => 'smtp.mailgun.org',
		              :port       	=> '587',
		              :user_name    => 'postmaster@nowmov.mailgun.org',
		              :password   	=> 'Baneling Bust',
		              :authentication   => :plain,
		              :domain     	=> 'nowmov.mailgun.org'
		             }
		           )
		  "Email sent!"		
		end

    get '/test_api' do
			# Sending a simple text message:
# 			MailgunMessage::send_text("me@nowmov.mailgun.org",
# 			                          "fahdoo@nowmov.com",
# 			                          "Hello text Ruby API",
# 			                          "Hi!\nI am sending the message using Mailgun Ruby API")
			
			# Sending a simple text message + tag
# 			MailgunMessage::send_text("me@samples.mailgun.org",
# 			                          "you@yourhost, 'Him' <you@mailgun.info>",
# 			                          "Hello text Ruby API",
# 			                          "Hi!\nI am sending the message using Mailgun Ruby API",
# 			                          "",
# 			                          {:headers => {MailgunMessage::MAILGUN_TAG => "sample_text_ruby"}})


			
			# Sending a MIME message:		
			@sender   = "notifier@nowmov.mailgun.org"
			@receiver = "fahdoo@nowmov.com"
			raw_mime =
			  "X-Mailgun-Tag: sample_raw_ruby\n" +
			  "Content-Type: text/plain;charset=utf-8\n" +
			  "From: #{sender}\n" +
			  "To: #{receiver}\n" +
			  "Content-Type: text/plain;charset=utf-8\n" +
			  "Subject: Hello raw Ruby API!\n" +
			  "\n" +
			  "Sending the message using Mailgun Ruby API"
 			MailgunMessage::send_raw(@sender, @receiver, raw_mime)			

			"Messages sent"

    end  	
  end
end
