require './spec_helper.rb'

describe Ushmm::DigitalCollections::Component do

	before :each do
		@series_component = Ushmm::DigitalCollections::Component.new :series, "a test series component"
	end

	describe '#new' do
		it 'returns a new Component object' do
			@series_component.should be_an_instance_of Ushmm::DigitalCollections::Component
		end
		it 'takes exactly 2 parameters' do
			lambda { Ushmm::DigitalCollections::Component.new :series }.should raise_exception ArgumentError
			lambda { Ushmm::DigitalCollections::Component.new :series, "a test series", :something_extra }.should raise_exception ArgumentError
		end
		it 'takes a Symbol as first argument, otherwise throw ArgumentError' do
			lambda { Ushmm::DigitalCollections::Component.new 'series', 'this part is fine' }.should raise_exception ArgumentError
		end
		it 'only accepts a true component level type as first argument, otherwise throw ArgumentError' do
			lambda { Ushmm::DigitalCollections::Component.new :sereez, 'this part is fine' }.should raise_exception ArgumentError
		end
	end

	describe '#designation' do
		it 'should return the correct designation' do
			@series_component.designation.should == "a test series component"
		end
	end	

	describe '#designation=' do
		it "is not defined.  #{described_class} does not allow designation to be set after object initialization." do
			lambda { @series_component.designation = 'a new designation' }.should raise_exception NoMethodError
		end
	end

	describe '#level_type' do
		it 'returns the correct level_type' do
			@series_component.level_type.should == :series
		end
	end

	describe '#level_type=' do
		it "is not defined.  #{described_class} does not allow level_type to be set after object initialization." do
			lambda { @series_component.level_type = :series }.should raise_exception NoMethodError
		end
	end

	describe '#add_child' do
		it 'returns a new Component object' do
			(@series_component.add_child :subseries, "a test subseries child").should be_an_instance_of Ushmm::DigitalCollections::Component
		end
		it 'takes exactly 2 parameters' do
			lambda { @series_component.add_child :subseries }.should raise_exception ArgumentError
			lambda { @series_component.add_child :subseries, "a test series", :something_extra }.should raise_exception ArgumentError
		end
		it 'takes a Symbol as first argument, otherwise throw ArgumentError' do
			lambda { @series_component.add_child 'subseries', 'this part is fine' }.should raise_exception ArgumentError
		end
		it 'only accepts a true component level type as first argument, otherwise throw ArgumentError' do
			lambda { @series_component.add_child :subbsereez, 'this part is fine' }.should raise_exception ArgumentError
		end
		it 'does not allow the nesting of incompatible types' do
			lambda { @series_component.add_child :series, "a series under a series is bad" }.should raise_exception RuntimeError
		end
		it 'does not allow two children of the same name, raises IndexError' do
			(@series_component.add_child :series, "same name series").should be_an_instance_of Ushmm::DigitalCollections::Component
			lambda { @series_component.add_child :series, "same name series" }.should raise_exception IndexError
		end
	end

	describe '#children' do
		context "with children" do
			before :each do
				@series_component.add_child :subseries, "a test subseries"
			end
			it 'returns an Array of child Component\'s' do
				@series_component.should have(1).children
				@series_component.children[0].should be_an_instance_of Ushmm::DigitalCollections::Component
			end
		end
		context "with no children" do
			it 'returns an empty list (since no children)' do
				@series_component.should have(0).children
			end
		end
	end

	describe '#parent' do
		context "with children" do
			before :each do
				@child_component = @series_component.add_child :subseries, "a test subseries"
			end
			it 'returns an Array of child Component\'s' do
				@child_component.parent.should be_an_instance_of Ushmm::DigitalCollections::Component
			end
		end
		context "with no children" do
			it 'returns an empty list (since no children)' do
				@series_component.should have(0).children
			end
		end
	end

	describe '#find_child_by_designation' do
		before :each do
			@series_component.add_child :subseries, "a test subseries"
		end
		it 'returns the Component as specified by its designation.' do
			x = @series_component.find_child_by_designation 'a test subseries'
			x.should be_an_instance_of Ushmm::DigitalCollections::Component
			x.designation.should == 'a test subseries'
		end
		it 'raises an Exception when child is not found' do
			lambda { @series_component.find_child_by_designation 'a missing subseries' }.should raise_exception IndexError
		end
	end

	describe '#[]' do
		before :each do
			@series_component.add_child :subseries, "a test subseries"
		end
		it 'returns the Component as specified by its designation.' do
			x = @series_component['a test subseries']
			x.should be_an_instance_of Ushmm::DigitalCollections::Component
			x.designation.should == 'a test subseries'
		end
		it 'returns nil when child component is not found.' do
			x = @series_component['a missing subseries']
			x.should == nil
		end
	end

	describe '#remove_child' do
		before :each do
			@series_component.add_child :subseries, "a test subseries to keep"
			@series_component.add_child :subseries, "a test subseries to remove"
		end
		it 'removes a child spcified by argument' do
			@series_component.remove_child('a test subseries to remove')
			@series_component['a test subseries to keep'].should_not == nil
			@series_component['a test subseries to remove'].should == nil			
		end
	end

	context 'more complex structure' do
		before :each do
			@ss1 = @series_component.add_child :subseries, "a test subseries to keep"
			@ss2 = @series_component.add_child :subseries, "a test subseries to remove"
			@item1_1 = @ss1.add_child :item, "item 1.1"
			@item1_2 = @ss1.add_child :item, "item 1.2"
			@item1_3 = @ss1.add_child :item, "item 1.3"
			@item2_1 = @ss2.add_child :item, "item 2.1"
			@item2_2 = @ss2.add_child :item, "item 2.2"
		end
		describe 'complex tests' do
			it 'removes a child spcified by argument' do
				@series_component.remove_child('a test subseries to remove')
				@series_component['a test subseries to keep'].should_not == nil
				@series_component['a test subseries to remove'].should == nil			
			end
		end
		describe '#ancestors' do
			it 'returns an array of given component\'s ancestors' do
				@item1_1.ancestors.should == [@series_component, @ss1, @item1_1]
			end
		end
		describe '#descendants' do
			it 'returns an array of component\'s descendants, starting with immediate child' do
				@item1_1.ancestors.should == [@series_component, @ss1, @item1_1]
			end
		end
	end
end


