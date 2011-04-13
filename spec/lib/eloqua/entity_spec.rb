require 'spec_helper'

describe Eloqua::Entity do
  
  subject do
    Class.new(Eloqua::Entity) do
      self.remote_object_type = Eloqua::API.remote_object_type('Contact')
      def self.name
        'ContactEntity'
      end
    end
  end
  
  it_behaves_like 'supports CURD remote operations', :entity
  
  context "#self.remote_object" do
    specify { subject.remote_object.should == :entity }        
  end
  
  context '#self.remote_object_type_tag' do
    specify { subject.remote_object_type_tag.should == 'entityType' }
  end  
  
  context "#self.build_query" do
    
    context "when using a string" do
      
      let(:input) do
        "C_EmailAddress = 'test'"
      end
      
      it 'should return given value' do
        subject.build_query(input).should == input
      end
            
    end
    
    context 'when using a hash' do
            
      let(:klass) do
        Class.new(subject) do
          map :C_EmailAddress => 'email'
        end
      end
      
      it 'should generate query string using map_attribute on mapped attributes' do
        klass.build_query(:email => 'test').should == "C_EmailAddress='test'"
      end
      
      it 'should use given attribute name when none is mapped' do
        klass.build_query(:C_Company => 'company').should == "C_Company='company'"
      end
      
      it 'should join coniditons with and' do
        email_param = "C_EmailAddress='test'"
        company_param = "C_Company='company'"
        
        result = klass.build_query(:email => 'test', :C_Company => 'company')
        result.should include(email_param)
        result.should include(company_param)
        result.should include(' AND ')
      end
      
    end
    
  end  
  
  context '#self.where' do
    
    let(:klass) do
      Class.new(subject) do
        map :C_EmailAddress => :email
      end
    end
    
    context "when successfuly finding single result with all fields" do
    
      let(:input) { {:email => 'james@lightsofapollo.com'} }
      let(:xml_body) do
        api = subject.api
        xml! do |xml|
          xml.eloquaType do
            xml.template!(:object_type, api.remote_object_type('Contact'))
          end
          xml.searchQuery("C_EmailAddress='james@lightsofapollo.com'")
          xml.pageNumber(1)
          xml.pageSize(200)
        end
      end
      
      before do
        mock = soap_fixture(:query, :contact_email_one)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, :query, xml_body).and_return(mock)
        @results = klass.where(input)
      end
      
      it 'should return an array' do
        @results.class.should == Array
      end
      
      it 'should return an array of objects' do
        @results.first.class.should == klass
      end
      
      it 'should have attributes acording to XML file (query/contact_email_one.xml)' do
        record = @results.first
        expected = {
          :id => '1',
          :email => 'james@lightsofapollo.com',
          :first_name => 'James'
        }
        record.attributes.length.should == 3
        expected.each do |attr, value|
          record.attributes[attr].should == value
        end
      end
      
    end
    
    context "when rows are not found" do
      let(:input) { {:email => 'james@lightsofapollo.com'} }
      let(:xml_body) do
        api = subject.api
        
        xml! do |xml|
          xml.eloquaType do
            xml.template!(:object_type, api.remote_object_type('Contact'))
          end
          xml.searchQuery("C_EmailAddress='james@lightsofapollo.com'")
          xml.pageNumber(1)
          xml.pageSize(200)
        end
      end
      
      before do
        mock = soap_fixture(:query, :contact_missing)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, :query, xml_body).and_return(mock)
        @results = klass.where(input)
      end
      
      specify { @results.should be_false }
      
    end
    
  end  
  
  
  
end