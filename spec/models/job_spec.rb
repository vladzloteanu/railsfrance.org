require 'spec_helper'

describe Job do
  before(:each) do
    Job.any_instance.stub(:geocode) { [1,1] }
    Factory(:job)
  end
  let(:job) { Job.first }

  describe "validations" do
    it { should validate_presence_of(:company) }
    it { should validate_presence_of(:street) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:description) }
    #url
    it { should validate_format_of(:url).with('http://railsfrance.org') }
    it { should validate_format_of(:url).with('http://www.railsfrance.org') }
    it { should validate_format_of(:url).with('https://railsfrance.org') }
    it { should validate_format_of(:url).with('https://www.railsfrance.org') }
    #email
    it { should validate_presence_of(:email) }
    it { should validate_format_of(:email).with('p@o.fr') }
    #postal_code
    it { should validate_presence_of(:postal_code) }
    it { should validate_format_of(:postal_code).with(75018) }
    it { should validate_format_of(:postal_code).not_with(5018) }
    it { should validate_format_of(:postal_code).not_with(750183) }
    #title
    it { should validate_presence_of(:title) }
    it { should validate_uniqueness_of(:title) }
    it { should ensure_length_of(:title).is_at_most(100) }

    it "should validate #validate_contracts" do
      job.should_receive(:validate_contracts)
      job.valid?
    end
  end

  describe 'state_machine' do
    context 'states' do
      its(:state) { job.state.should eql 'pending' }
      it { should respond_to :confirm }
      it { should respond_to :activate }
    end

    context "confirmed transition" do
      it "should allow transition from :pending to :confirmed" do
        job.confirm
        job.state.should eql 'confirmed'
      end
      it "should call Job#generate_token on after_transition :pending => :confirmed" do
        job.should_receive :generate_token
        job.confirm
      end
    end

    context "activated transition" do
      let(:job) { Factory(:job, state: 'confirmed') }

      it "should allow transition from :confirmed to :activated and call Job#notify_observers with :after_activation" do
        job.should_receive(:notify_observers).with(:after_activation)
        job.activate
        job.state.should eql 'activated'
      end
    end
  end

  describe '#to_s' do
    it "should return title" do
      job.to_s.should eql job.title
    end
  end

  describe '#contracts' do
    subject { job.contracts }
    it { should be_an_instance_of(Array) }
    it { should eql [:cdi]}
  end

  describe '#generate_token' do
    after(:each) do
      job.generate_token
    end
    it "should update #token" do
      job.should_receive(:update_attribute).with(:token, kind_of(String))
    end
    it "should use SecureRandom.hex" do
      SecureRandom.should_receive(:hex).with(13).once()
    end
  end

  describe '#validate_contracts' do
    it "should add an error if there is contracts" do
      job.cdi = false
      job.valid?
      job.errors.messages.should have_key :contracts_error
    end
  end
end
