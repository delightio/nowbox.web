module HTTPSteps
  def included base
    base.instance_eval do
      [200, 201, 400, 401, 403, 404].each do |code|
        Then "the status code should be #{code}" do
          last_response.status.should == code
        end
      end

      And 'there should be an error' do
        last_response.body.should =~ /error/
      end
    end
  end
end
