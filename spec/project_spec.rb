require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Project do
  include DatabaseSpecHelper

  def klass
    Integrity::Project
  end

  before(:each) { @project = klass.generate }

  specify "fixture should be valid" do
    klass.gen.should be_valid
  end

  it 'should not be valid' do
    klass.new.should_not be_valid
  end

  it "requires a name" do
    klass.make(:name => nil).should_not be_valid
  end

  it "requires a permalink" do
    klass.new(:permalink => nil).should_not be_valid
  end

  it "requires an URI" do
    klass.make(:uri => nil).should_not be_valid
  end

  it "requires a build command" do
    klass.make(:command => nil).should_not be_valid
  end

  it "requires a branch" do
    klass.make(:branch => nil).should_not be_valid
  end

  it 'should validates name uniqueness' do
    klass.generate(:name => @project.name).errors.on(:name).should include('Name is already taken')
  end

  it 'should have a name' do
    @project.name = 'Integrity'
    @project.name.should == 'Integrity'
  end

  it 'should have a repository URI' do
    @project.uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @project.uri.should be_an_instance_of(Addressable::URI)
  end

  it 'should have a repository branch' do
    @project.branch = 'development'
    @project.branch.should == 'development'
  end

  it "should have a default project branch of 'master'" do
    klass.new.branch.should == "master"
  end

  it 'should have a build command' do
    @project.command = 'rake spec'
    @project.command.should == 'rake spec'
  end

  it 'should have a default build command' do
    klass.new.command.should == 'rake'
  end

  it 'should have a visibility' do
    @project.public = false
    @project.should_not be_public
  end

  it 'should be puublic by default' do
    @project.should be_public
  end

  describe "Setting the permalink" do
    before do
      @project = klass.make(:name => "Integrity")
    end

    it "should set the permalink on save" do
      @project.permalink.should be_nil
      @project.save
      @project.permalink.should == "integrity"
    end

    it "should update the permalink if the name changes" do
      @project.name = "Foca's Awesome Project & Strange Name"
      @project.save
      @project.permalink.should == "focas-awesome-project-and-strange-name"
    end

    it "should not ends up having dashes at the end" do
      @project.name = "Ends in symbols!@%^"
      @project.save
      @project.permalink.should == "ends-in-symbols"
    end
  end

  describe "Ensuring the public/private status" do
    before { @project = klass.make }

    it "should be public after saving" do
      @project.public = true
      @project.save
      @project.reload.should be_public
    end

    it "should not be public if set to false" do
      @project.public = false
      @project.save
      @project.reload.should_not be_public
    end

    it "should be public if set to any non-false value" do
      @project.public = "false"
      @project.save
      @project.reload.should be_public
    end
  end

  describe "Building itself" do
    before do
      @project = klass.generate
      @builder = mock('Builder', :build => true)
      Integrity::Builder.stub!(:new).and_return(@builder)
    end

    it "should not build if it's already building" do
      @project.stub!(:building?).and_return(true)
      Integrity::Builder.should_not_receive(:new)
      @project.build
    end

    it 'should instantiate a new Builder and pass itself to it' do
      Integrity::Builder.should_receive(:new).with(@project).and_return(@builder)
      @project.build
    end

    it 'should tell the builder to build the head if no commit id is passed' do
      @builder.should_receive(:build).with("HEAD")
      @project.build
    end

    it "should tell the builder to build a specific commit if an id is passed" do
      @builder.should_receive(:build).with('6eba34d94b74fe68b96e35450fadf241113e44fc')
      @project.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
    end

    it "should set 'building?' to true while building" do
      @builder.should_receive(:build) { @project.should be_building }
      @project.build
    end

    it "should set 'building?' to false after a build" do
      @project.build
      @project.should_not be_building
    end

    it "should ensure 'building?' is false even if the build raises an exception" do
      lambda do
        @builder.stub!(:build).and_raise(RuntimeError)
        @project.build
        @project.should_not be_building
      end.should raise_error(RuntimeError)
    end
    
    it "should deliver the corresponding notifications after building" do
      @project.should_receive(:send_notifications)
      @project.build
    end
  end

  describe "When searching for its previous builds, given it has 5 builds" do
    it "should find the last build by ordering chronologically" do
      @project.builds.should_receive(:last)
      @project.last_build
    end

    it "should have 4 previous builds" do
      @project.should have(4).previous_builds
    end

    it "should return an empty array if it has only one build" do
      klass.generate(:builds => 1.of { Integrity::Build.make }).previous_builds.should be_empty
    end

    it "should return an empty array if there are no builds" do
      klass.generate(:builds => []).previous_builds.should be_empty
    end
  end

  describe "Determining its status" do
    it "should return the status of its last build" do
      @project.status.should == :success
    end

    it "should return nil if it has never been built" do
      klass.generate(:builds => []).status.should be_nil
    end
  end
  
  describe "Getting destroyed" do
    before do
      @builder = mock("Builder", :delete_code => true)
      Integrity::Builder.stub!(:new).with(@project).and_return(@builder)
      @project.update_attributes(:name => "Integrity", :uri => "git://github.com/foca/integrity.git")
      @project.builds.stub!(:destroy!)
    end

    it "should delete all the project builds" do
      @project.builds.should_receive(:destroy!)
      @project.destroy
    end

    it "should tell the builder to delete the code for this project" do
      @builder.should_receive(:delete_code).and_return(true)
      @project.destroy
    end
  end
  
  describe "Getting the config for a Notifier" do
    before do
      @project.update_attributes(:name => "Integrity", :uri => "git://github.com/foca/integrity.git")
      @project.notifiers.create(:name => "Stub", :config => { :a => 1 })
    end
    
    it "should return the correct configuration if the notifier was registered for the project" do
      @project.config_for(Integrity::Notifier::Stub).should == { :a => 1 }
    end
    
    it "should return an empty hash if the notifier was not registered for the project" do
      class Integrity::Notifier::Twitter; end # we don't care if the class actually exists or does anything
      @project.config_for(Integrity::Notifier::Twitter).should == {}
    end
  end
  
  describe "Sending notifications" do
    def mock_build
      @build ||= mock("build", :short_commit_identifier => "7be5d6d" )
    end
    
    before do
      @project.update_attributes(:name => "Integrity", :uri => "git://github.com/foca/integrity.git")
      @email_notifier = @project.notifiers.create(:name => "Email")
      @email_notifier.stub!(:notify_of_build)
      @project.stub!(:notifiers).and_return([@email_notifier])
      @project.stub!(:last_build).and_return(mock_build)
      Integrity.logger.stub!(:info)
    end
    
    it "should iterate over the list of notifiers" do
      @project.notifiers.should_receive(:each)
      @project.send(:send_notifications)
    end
    
    it "should call #notify_of_build on each notifier" do
      @email_notifier.should_receive(:notify_of_build).with(mock_build)
      @project.send(:send_notifications)
    end

    it "should protect itself from eventual timeout error" do
      @email_notifier.stub!(:notify_of_build).and_raise(Timeout::Error)
      lambda do
        @project.send(:send_notifications)
      end.should_not raise_error
    end

    it "should log timeout" do
      @email_notifier.stub!(:notify_of_build).and_raise(Timeout::Error)
      Integrity.logger.should_receive(:info).with("Email notifier timed out")
      @project.send(:send_notifications)
    end

    it "should log notifications it sends" do
      Integrity.logger.should_receive(:info).with("Notifying of build 7be5d6d using the Email notifier")
      @project.send(:send_notifications)
    end
  end
end
