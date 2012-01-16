require File.expand_path("../../spec_helper", __FILE__)

describe "Time#age" do
  it "prints out just now if diff is zero" do
    from = Time.now
    subject = from

    subject.age(from).should == "Just now"
  end

  it "prints out nicely format time diff" do
    from = Time.now
    subject = from

    subject -= 2.seconds
    subject -= 3.minutes
    subject -= 4.hours
    subject -= 5.days
    subject -= 6.weeks

    subject.age(from).should == "6w 5d 4h 3m 2s ago"
  end

  it "skips printing out the unit if zero" do
    from = Time.now
    subject = from - 3.minutes

    subject.age(from).should == "3m ago"
  end

  it "handles future time as well" do
    from = Time.now
    subject = from + 1.days

    subject.age(from).should == "1d later"
  end
end